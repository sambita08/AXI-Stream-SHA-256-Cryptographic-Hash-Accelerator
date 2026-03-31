`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sambita Dutta
// 
// Create Date: 17.03.2026 16:27:58
// Design Name: 
// Module Name: tb_sha
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for sha256.v 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ps/1ps

module tb_sha ();

initial $dumpvars(1, tb_sha);

reg rstn = 1'b0;
reg clk = 1'b1;
always #5000 clk = ~clk;   // 100MHz clock



reg          tvalid = 1'b0;
reg          tlast  = 1'b0;
reg  [ 31:0] tid    = 0;
reg  [  7:0] tdata  = 8'd0;


wire         tready_sha256;
wire         tready = tready_sha256;
wire         ovalid_sha256;
wire [ 31:0] oid_sha256;
wire [ 60:0] olen_sha256;
wire [255:0] osha256;

sha256 u_sha256 (
    .rstn   ( rstn          ),
    .clk    ( clk           ),
    .tready ( tready_sha256 ),
    .tvalid ( tvalid        ),
    .tlast  ( tlast         ),
    .tid    ( tid           ),
    .tdata  ( tdata         ),
    .ovalid ( ovalid_sha256 ),
    .oid    ( oid_sha256    ),
    .olen   ( olen_sha256   ),
    .osha   ( osha256       )
);

// OUTPUT MONITOR
always @ (posedge clk)
    if (ovalid_sha256)
        // Format: id=<hex>   len=<decimal>   sha256=<hex>
        $display("id=%x   len=%6d   sha256=%x", oid_sha256, olen_sha256, osha256);



//// HELPER FUNCTION: check_fopen
// Validates that $fopen succeeded. If file pointer is 0 (null),
// the file could not be opened — print error and stop simulation.
function  integer check_fopen;
    input integer fp;
begin
    if(fp == 0) begin
        $error("could not open file.\n");
        $finish;
    end
    check_fopen = fp;
end
endfunction


// TASK: push_file
// Reads a binary file byte-by-byte and streams it into the
// SHA-256 module


task push_file;
    input integer id;      // 32-bit message identifier
    input integer fp;      //file pointer returned by $fopen
    integer       rbyte;   // Current byte read from file
begin
    {tvalid,tlast,tid,tdata} <= 0;
    @(posedge clk);
    
    
    // Wait until the module is ready to accept the first byte
    while(~tready) @(posedge clk);
    // Set message ID and read the first byte
    tid <= id;
    tdata <= $fgetc(fp);        // First byte
    rbyte  = $fgetc(fp);        // Peek at second byte to check for EOF
    tlast <= rbyte == -1;       // If only one byte in file, it's also the last
    
    
   // Stream remaining bytes
    while( rbyte != -1 ) @(posedge clk) begin
        if(~tvalid | tready)
            tvalid <= ($random % 2) == 0;           // add random bubble
        
        // When the current transfer is accepted 
        if( tvalid & tready) begin          
            tdata <= rbyte; // Put next byte on bus
            rbyte  = $fgetc(fp);
            tlast <= rbyte == -1;
        end
    end
    tvalid <= 1'b1;
    while(~tready) @(posedge clk);
    @(posedge clk);
    {tvalid,tlast,tid,tdata} <= 0;
    $fclose(fp);
end
endtask



initial begin
    
    // Hold reset for 4 clock cycles 
    repeat(4) @(posedge clk);
    rstn <= 1'b1;
    
    // Send test files sequentially
    // The SHA-256 pipeline is deep enough that a new file can begin
    // before the previous one finishes compression (pipelined operation)
    push_file('h111, check_fopen($fopen("./test_data/test1.bin", "rb")));
    push_file('h222, check_fopen($fopen("./test_data/test2.bin", "rb")));
    push_file('h333, check_fopen($fopen("./test_data/test3.bin", "rb")));
    push_file('h444, check_fopen($fopen("./test_data/test4.bin", "rb")));
    //push_file('h555, check_fopen($fopen("./test_data/test5.bin", "rb")));
    //push_file('h666, check_fopen($fopen("./test_data/test6.bin", "rb")));
   // push_file('h777, check_fopen($fopen("./test_data/test7.bin", "rb")));
    repeat(2000) @(posedge clk); // Wait for pipeline to flush — SHA-256 has ~70+ cycle latency
    $finish;
end


endmodule
