`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  Sambita Dutta
// 
// Create Date: 17.03.2026 16:26:00
// Design Name: 
// Module Name: sha256
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Pipelined hardware implementation of the SHA-256 cryptographic
//               hash algorithm. Accepts byte-stream input via an AXI4-Stream-like
//              interface, performs SHA-256 padding and compression internally,
//              and outputs a 256-bit digest once all input data is processed.
// 
// 
// Padding      : Hardware-managed (0x80 byte, zero-fill, 64-bit big-endian length)
// Output       : 256-bit hash (osha), valid flag (ovalid), message ID (oid)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module sha256(
    input  wire         rstn,           // Active-low synchronous reset
    input  wire         clk,
    // input interface
    output wire         tready,         // Module ready to accept input data
    input  wire         tvalid,         // Upstream data valid
    input  wire         tlast,          // Last byte of message indicator
    input  wire [ 31:0] tid,            // Message ID tag (for tracking multiple messages)
    input  wire [  7:0] tdata,          // Input byte (data fed one byte at a time)

    // output interface
    output reg          ovalid,         // Output hash is valid
    output reg  [ 31:0] oid,            // Message ID of the completed hash
    output reg  [ 60:0] olen,           // Length of the original message in bytes
    output wire [255:0] osha            // Final 256-bit SHA-256 digest
);



//  SHA-256 SIGMA FUNCTIONS
//  SSIG = Small Sigma (used in message schedule expansion)
// BSIG = Big Sigma (used in compression round function)

function  [31:0] SSIG0;
    input [31:0] x;
begin
    // Small Sigma 0: ROTR^7(x) XOR ROTR^18(x) XOR SHR^3(x)
    SSIG0 = {x[6:0],x[31:7]} ^ {x[17:0],x[31:18]} ^ {3'h0,x[31:3]};
end
endfunction


function  [31:0] SSIG1;
    input [31:0] x;
begin
    // Small Sigma 1: ROTR^17(x) XOR ROTR^19(x) XOR SHR^10(x)
    SSIG1 = {x[16:0],x[31:17]} ^ {x[18:0],x[31:19]} ^ {10'h0,x[31:10]};
end
endfunction


function  [31:0] BSIG0;
    input [31:0] x;
begin
    // Big Sigma 0: ROTR^2(x) XOR ROTR^13(x) XOR ROTR^22(x)
    BSIG0 = {x[1:0],x[31:2]} ^ {x[12:0],x[31:13]} ^ {x[21:0],x[31:22]};
end
endfunction


function  [31:0] BSIG1;
    input [31:0] x;
begin
    // Big Sigma 1: ROTR^6(x) XOR ROTR^11(x) XOR ROTR^25(x)
    BSIG1 = {x[5:0],x[31:6]} ^ {x[10:0],x[31:11]} ^ {x[24:0],x[31:25]};
end
endfunction



//SHA-256 ROUND CONSTANTS (K[0..63])
// 64 constant 32-bit words derived from the fractional parts
// of the cube roots of the first 64 prime numbers.

wire [31:0] k [0:63];
assign k[ 0] = 'h428a2f98;
assign k[ 1] = 'h71374491;
assign k[ 2] = 'hb5c0fbcf;
assign k[ 3] = 'he9b5dba5;
assign k[ 4] = 'h3956c25b;
assign k[ 5] = 'h59f111f1;
assign k[ 6] = 'h923f82a4;
assign k[ 7] = 'hab1c5ed5;
assign k[ 8] = 'hd807aa98;
assign k[ 9] = 'h12835b01;
assign k[10] = 'h243185be;
assign k[11] = 'h550c7dc3;
assign k[12] = 'h72be5d74;
assign k[13] = 'h80deb1fe;
assign k[14] = 'h9bdc06a7;
assign k[15] = 'hc19bf174;
assign k[16] = 'he49b69c1;
assign k[17] = 'hefbe4786;
assign k[18] = 'h0fc19dc6;
assign k[19] = 'h240ca1cc;
assign k[20] = 'h2de92c6f;
assign k[21] = 'h4a7484aa;
assign k[22] = 'h5cb0a9dc;
assign k[23] = 'h76f988da;
assign k[24] = 'h983e5152;
assign k[25] = 'ha831c66d;
assign k[26] = 'hb00327c8;
assign k[27] = 'hbf597fc7;
assign k[28] = 'hc6e00bf3;
assign k[29] = 'hd5a79147;
assign k[30] = 'h06ca6351;
assign k[31] = 'h14292967;
assign k[32] = 'h27b70a85;
assign k[33] = 'h2e1b2138;
assign k[34] = 'h4d2c6dfc;
assign k[35] = 'h53380d13;
assign k[36] = 'h650a7354;
assign k[37] = 'h766a0abb;
assign k[38] = 'h81c2c92e;
assign k[39] = 'h92722c85;
assign k[40] = 'ha2bfe8a1;
assign k[41] = 'ha81a664b;
assign k[42] = 'hc24b8b70;
assign k[43] = 'hc76c51a3;
assign k[44] = 'hd192e819;
assign k[45] = 'hd6990624;
assign k[46] = 'hf40e3585;
assign k[47] = 'h106aa070;
assign k[48] = 'h19a4c116;
assign k[49] = 'h1e376c08;
assign k[50] = 'h2748774c;
assign k[51] = 'h34b0bcb5;
assign k[52] = 'h391c0cb3;
assign k[53] = 'h4ed8aa4a;
assign k[54] = 'h5b9cca4f;
assign k[55] = 'h682e6ff3;
assign k[56] = 'h748f82ee;
assign k[57] = 'h78a5636f;
assign k[58] = 'h84c87814;
assign k[59] = 'h8cc70208;
assign k[60] = 'h90befffa;
assign k[61] = 'ha4506ceb;
assign k[62] = 'hbef9a3f7;
assign k[63] = 'hc67178f2;



// SHA-256 INITIAL HASH VALUES (H0..H7)
// Derived from the fractional parts of the square roots of
// the first 8 prime numbers. 

integer i;

wire [31:0] hinit [0:7];         // Constant initial hash values (ROM)
reg  [31:0] h     [0:7];        // Working hash state (updated each round)
reg  [31:0] hsave [0:7];        // Snapshot of h[] at start of compression block
reg  [31:0] hadder[0:7];        // Addback values: hsave added after 64 rounds
assign hinit[0] = 'h6a09e667;
assign hinit[1] = 'hbb67ae85;
assign hinit[2] = 'h3c6ef372;
assign hinit[3] = 'ha54ff53a;
assign hinit[4] = 'h510e527f;
assign hinit[5] = 'h9b05688c;
assign hinit[6] = 'h1f83d9ab;
assign hinit[7] = 'h5be0cd19;

// Initialize all hash registers to 0
initial for(i=0; i<8; i=i+1) h[i] = 0;
initial for(i=0; i<8; i=i+1) hsave[i] = 0;
initial for(i=0; i<8; i=i+1) hadder[i] = 0;



// MESSAGE SCHEDULE AND BYTE BUFFER
// w[0..15]: 16-word sliding window for message schedule (W)
// buff[0..63]: raw byte buffer to collect one 512-bit block


reg [31:0] w [0:15];        // Message schedule window (W_t), 16 x 32-bit words
reg [ 7:0] buff [0:63];     // Raw byte input buffer (one 512-bit = 64-byte block)

initial for(i=0; i<16; i=i+1) w[i] = 0;
initial for(i=0; i<64; i=i+1) buff[i] = 8'd0;


//FSM STATE DEFINITIONS FOR PADDING
localparam [2:0] IDLE   = 3'd0,     // waiting for first byte
                 RUN    = 3'd1,     //streaming bytes in
                 ADD8   = 3'd2,     // append mandatory 0x80 padding byte
                 ADD0   = 3'd3,     //append zero-padding bytes
                 ADDLEN = 3'd4,     //append 64-bit big-endian message length
                 DONE   = 3'd5;     //padding complete, return to IDLE
reg  [ 2:0] status = IDLE;

reg  [60:0] cnt = 61'd0;         // Total bytes received (original message)
reg  [ 5:0] tcnt = 6'd0;         // Position within current 64-byte block (0–63)
wire [63:0] bitlen = {cnt,3'h0}; // Message bit-length = cnt << 3 (multiply by 8)



//PIPELINE STAGE REGISTERS
//   i-stage  : input/padding FSM output
//   m-stage  : block boundary detection (triggers compression)
//   w-stage  : message schedule (W) computation
//   wk-stage : W[t] + K[t] pre-addition before compression


// --- i-stage (Input/Padding stage) ---
wire       iinit;               //PULSE: start of new message- 1st byte
reg        ifirst = 1'b0;       
reg        ivalid = 1'b0;
reg        ilast = 1'b0;        //last byte of padded message
reg [60:0] ilen  = 61'd0;       //message length
reg [31:0] iid = 0;             //message id 
reg [ 7:0] idata = 8'd0;        //current byte (real data or padding)
reg [ 5:0] icnt = 6'd0;         //byte index


// --- m-stage (Memory/Block stage) ---
reg        minit= 1'b0;         //pulse : initiation of hash stage -- start of msg
reg        men  = 1'b0;
reg        mlast = 1'b0;
reg [31:0] mid = 0;
reg [60:0] mlen = 61'd0;
reg [ 5:0] mcnt = 6'd0;         // Round counter within compression (0–63)


// --- w-stage (Message Schedule stage) ---
reg        winit  = 1'b0;       //pass through of minit
reg        wen  = 1'b0;
reg        wlast = 1'b0;        //last round of last block
reg [31:0] wid = 0;
reg [60:0] wlen = 61'd0;
reg        wstart = 1'b0;       // Pulse at round 0 (save current h[] → hsave)
reg        wfinal = 1'b0;       // Pulse at round 63 (trigger hadder load)
reg [31:0] wadder = 0;          // k[mcnt]: round constant for this cycle       


 
// --- wk-stage (W+K pre-adder stage) ---
reg        wkinit  = 1'b0;
reg        wken = 1'b0;
reg        wklast = 1'b0;
reg [31:0] wkid = 0;
reg [60:0] wklen = 61'd0;
reg        wkstart = 1'b0;
reg [31:0] wk = 0;               // w[0] + k[round]: pre-computed T1 partial sum

assign tready = (status==IDLE) || (status==RUN); //module accepts new data only in IDLE or RUN states
assign iinit  = (status==IDLE) & tvalid; // iinit : fires when first byte of a new message arrives



//NPUT FSM + PADDING STATE MACHINE
//   1. Append bit '1' (= byte 0x80)
//   2. Append zero bytes until block is 56 bytes full
//   3. Append 8-byte big-endian bit-length


always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        status <= IDLE;
        cnt <= 61'd0;
        tcnt <= 6'd0;
        {ivalid, ifirst, ilast, ilen, iid, idata} <= 0;
    end else begin
        ilen <= cnt;  // Latch message length for downstream pipeline
        case(status)
            IDLE   : begin
                if(tvalid) begin
                    status <= tlast ? ADD8 : RUN;
                    cnt <= 61'd1;
                end
                tcnt <= cnt[5:0] + 6'd1;
                ivalid <= tvalid;
                ifirst <= tvalid; // Mark as first block
                ilast  <= 1'b0;
                iid    <= tid;
                idata  <= tdata;
            end
            RUN     : begin
                if(tvalid) begin
                    status <= tlast ? ADD8 : RUN;
                    cnt <= cnt + 61'd1;
                end
                tcnt <= cnt[5:0] + 6'd1;
                ivalid <= tvalid;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= tdata;
            end
            ADD8    : begin  
                // If this byte lands at position 0x37 (55), we can fit the length
                // in the same block (positions 56–63). Otherwise we need extra zeros.
                status <= (cnt[5:0]==6'h37) ? ADDLEN : ADD0;
                tcnt <= cnt[5:0] + 6'd1;
                ivalid <= 1'b1;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= 8'h80;
            end
            ADD0    : begin
                // Append zero bytes until byte 55 (position 0x37) is reached,
                // leaving exactly 8 bytes for the length field.
                status <= (tcnt==6'h37) ? ADDLEN : ADD0;
                tcnt <= tcnt + 6'd1;
                ivalid <= 1'b1;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= 8'h00;
            end
            ADDLEN  : begin
                // Append 8-byte (64-bit) big-endian message bit-length.
                // bitlen[7:0] goes into byte 63, bitlen[63:56] goes into byte 56.
                // Indexing: bitlen[8*(7-tcnt[2:0]) +: 8] extracts the correct byte.
                status <= (tcnt==6'h3f) ? DONE : ADDLEN;
                tcnt <= tcnt + 6'd1;
                ivalid <= 1'b1;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= (tcnt==6'h3f);
                idata  <= bitlen[8*(7-tcnt[2:0])+:8];
            end
            default : begin
                status <= IDLE;
                cnt <= 61'd0;
                tcnt <= 6'd0;
                {ivalid, ifirst, ilast, ilen, idata} <= 0;
            end
        endcase
    end


// BYTE BUFFER (buff[0..63])
// Collects incoming bytes (data + padding) into a 64-byte
// buffer. icnt tracks which byte slot to write.
// iinit resets icnt so a new message starts filling from byte 0


always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        icnt <= 6'd0;
        for(i=0; i<64; i=i+1) buff[i] <= 8'd0;
    end else begin
        if(iinit) begin
            icnt <= 6'd0;
        end else if(ivalid) begin
            buff[icnt] <= idata;
            icnt <= icnt + 6'd1;
        end
    end
    
    
//M-STAGE — BLOCK BOUNDARY DETECTION
/// Detects when a full 64-byte block is in the buffer and
// triggers the 64-round compression sequence.
// minit: fires when the first block of a new message is ready
// men:   active for all 64 rounds of compression
// mcnt:  counts 0→63 (one round per clock)


always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        minit <= 1'b0;
        men   <= 1'b0;
        mlast <= 1'b0;
        mid   <= 0;
        mlen  <= 61'd0;
        mcnt  <= 6'd0;
    end else begin
        minit <= ifirst & (icnt==6'h3e);
        if(ifirst & (icnt==6'h3e)) begin
            men   <= 1'b0;
            mlast <= 1'b0;
            mcnt  <= 6'd0;
        end else if(ivalid & (icnt==6'h3f)) begin
            men   <= 1'b1;
            mlast <= ilast;
            mid   <= iid;
            mlen  <= ilen;
            mcnt  <= 6'd0;
        end else begin
            if(mcnt==6'h3f) begin
                men   <= 1'b0;
                mlast <= 1'b0;
            end
            if(men)
                mcnt <= mcnt + 6'd1;
        end
    end

// W-STAGE — MESSAGE SCHEDULE EXPANSION
// First 16 words (mcnt < 16): packed directly from buff[]
//   w[0] = {buff[4n], buff[4n+1], buff[4n+2], buff[4n+3]} (big-endian)
// Rounds 16–63: message schedule expansion formula
//   W[t] = SSIG1(W[t-2]) + W[t-7] + SSIG0(W[t-15]) + W[t-16]
// Implemented as a 16-deep shift register — w[0] is newest,
// w[15] is oldest. This saves 48 registers vs storing all 64 W words.


wire [5:0] waddr0, waddr1, waddr2, waddr3;
assign waddr0 = {mcnt[3:0],2'd0};
assign waddr1 = {mcnt[3:0],2'd1};
assign waddr2 = {mcnt[3:0],2'd2};
assign waddr3 = {mcnt[3:0],2'd3};

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        winit  <= 1'b0;
        wen    <= 1'b0;
        wlast  <= 1'b0;
        wid    <= 0;
        wlen   <= 61'd0;
        wstart <= 1'b0;
        wfinal <= 1'b0;
        wadder <= 0;
        for(i=0; i<16; i=i+1) w[i] <= 0;
    end else begin
        winit  <= minit;
        wen    <= men;
        wlast  <= mlast & (mcnt==6'h3f);
        wid    <= mid;
        wlen   <= mlen;
        wstart <= men & (mcnt==6'h00);
        wfinal <= men & (mcnt==6'h3f);
        wadder <= k[mcnt];
        
         // Message schedule word generation
        if(mcnt<6'd16)
            // Load W[0..15] directly from input buffer (big-endian byte packing)
            w[0] <= {buff[waddr0],buff[waddr1],buff[waddr2],buff[waddr3]};
        else
        
            // Expand W[16..63] using the schedule formula:
            w[0] <= SSIG1(w[1]) + w[6] + SSIG0(w[14]) + w[15];
        
        // Shift the window
        for(i=1; i<16; i=i+1) w[i] <= w[i-1];
    end


// WK-STAGE - W + K PRE-ADDER
// Pre-computes wk = W[t] + K[t] one cycle before it is used
// in the compression function. This breaks the critical timing
// path: instead of adding W+K inside the compression always
// block, the sum is ready one cycle early.
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        wkinit <= 1'b0;
        wken <= 1'b0;
        wklast <= 1'b0;
        wkid   <= 0;
        wklen  <= 61'd0;
        wkstart <= 1'b0;
        wk <= 0;
    end else begin
        wkinit <= winit;
        wken <= wen;
        wklast <= wlast;
        wkid   <= wid;
        wklen  <= wlen;
        wkstart <= wstart;
        wk <= w[0] + wadder;
    end



// HSAVE — SAVE HASH STATE AT START OF BLOCK
// At the beginning of each 64-round compression block,
// the current h[0..7] values are saved into hsave[].
// After all 64 rounds, hsave[] is added back to h[] to produce the final hash 
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) hsave[i] <= 0;
    end else begin
        if(wkstart)
            for(i=0; i<8; i=i+1) hsave[i] <= h[i];
    end


//HADDER — ADDBACK CONTROL
// hadder[] is loaded with hsave[] at wfinal (round 63),
// and zero otherwise. This allows the compression loop below
// to conditionally add the saved state only at the final round,
// effectively implementing:
// h[i] := h[i] (post-64-rounds) + hsave[i]
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) hadder[i] <= 0;
    end else begin
        if(wfinal) begin
            for(i=0; i<8; i=i+1) hadder[i] <= hsave[i];
        end else begin
            for(i=0; i<8; i=i+1) hadder[i] <= 0;
        end
    end

//Implements the 64-round iterative hash state update per FIPS 180-4
// T1 = h + Σ1(e) + Ch(e,f,g) + K[t] + W[t]
// T2 = Σ0(a) + Maj(a,b,c)

// New state: h=g, g=f, f=e, e=d+T1, d=c, c=b, b=a, a=T1+T2
//
// SHA-256 naming: a=h[0], b=h[1], c=h[2], d=h[3],
//                 e=h[4], f=h[5], g=h[6], h=h[7]
// hadder[] adds the saved pre-round state 



// T1 = h[7] + BSIG1(h[4]) + Ch(h[4],h[5],h[6]) + wk
// Ch(e,f,g) = (e AND f) XOR (NOT e AND g)
wire [31:0] t1 = ( h[7] + BSIG1(h[4]) + ((h[4] &  h[5]) ^ (~h[4] & h[6])) + wk );

// T2 = BSIG0(h[0]) + Maj(h[0],h[1],h[2])
// Maj(a,b,c) = (a AND b) XOR (a AND c) XOR (b AND c)
wire [31:0] t2 = ( BSIG0(h[0]) + ((h[0] & h[1]) ^ (h[0] & h[2]) ^ (h[1] & h[2])) );

always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) h[i] <= 0;
    end else begin
        if(wkinit) begin
            for(i=0; i<8; i=i+1) h[i] <= hinit[i];
        end else if(wken) begin
            h[7] <= hadder[7] + h[6];                // h ← g  (+hsave at round 63)
            h[6] <= hadder[6] + h[5];               // g ← f
            h[5] <= hadder[5] + h[4];               // f ← e
            h[4] <= hadder[4] + h[3] + t1;          // e ← d + T1
            h[3] <= hadder[3] + h[2];               // d ← c
            h[2] <= hadder[2] + h[1];               // c ← b
            h[1] <= hadder[1] + h[0];               // b ← a
            h[0] <= hadder[0] + t1 + t2;            // a ← T1 + T2
          
        end
    end


// OUTPUT STAGE
// ovalid is asserted the cycle after wklast (last wk round)
// osha is directly wired from h[0..7] — always valid when ovalid
initial {ovalid,oid,olen} = 0;
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        ovalid <= 1'b0;
        oid  <= 0;
        olen <= 61'd0;
    end else begin
        ovalid <= wklast;
        oid  <= wkid;
        olen <= wklen;
    end
assign osha = {h[0],h[1],h[2],h[3],h[4],h[5],h[6],h[7]};

endmodule
