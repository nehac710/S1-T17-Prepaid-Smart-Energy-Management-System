//Counter
module T_FF (input T, input clk, input reset, output reg Q);  //T flipflop module
    always @(posedge clk or posedge reset) begin
        if (reset)
            Q <= 0;
        else if (T)
            Q <= ~Q;
    end
endmodule

module date_counter (
    input date_1,
    input reset,
    output [4:0] date
);

    wire [4:0] next_date;
    wire [4:0] current_date;
    wire carry;
    
    // 5-bit register for storing the current date
    dff_5bit date_reg (
        .d(next_date),
        .clk(date_1),
        .reset(reset),
        .q(current_date)
    );
    
    // Incrementer
    full_adder fa0 (.a(current_date[0]), .b(1'b1), .cin(1'b0), .sum(next_date[0]), .cout(carry_0));
    full_adder fa1 (.a(current_date[1]), .b(1'b0), .cin(carry_0), .sum(next_date[1]), .cout(carry_1));
    full_adder fa2 (.a(current_date[2]), .b(1'b0), .cin(carry_1), .sum(next_date[2]), .cout(carry_2));
    full_adder fa3 (.a(current_date[3]), .b(1'b0), .cin(carry_2), .sum(next_date[3]), .cout(carry_3));
    full_adder fa4 (.a(current_date[4]), .b(1'b0), .cin(carry_3), .sum(next_date[4]), .cout(carry));
    
    // Reset logic
    wire reset_condition;
    and_gate and1 (current_date[0], current_date[1], and1_out);
    and_gate and2 (current_date[2], current_date[3], and2_out);
    and_gate and3 (current_date[4], and1_out, and3_out);
    and_gate and4 (and2_out, and3_out, reset_condition);
    
    // Mux for selecting between incremented value and 1 (reset value)
    mux_5bit mux (
        .a(next_date),
        .b(5'b00001),
        .sel(reset_condition),
        .y(date)
    );

endmodule

// 5-bit D Flip-Flop
module dff_5bit (
    input [4:0] d,
    input clk,
    input reset,
    output reg [4:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= 5'b00001;
        else
            q <= d;
    end
endmodule

// Full Adder
module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    wire w1, w2, w3;
    
    xor_gate xor1 (a, b, w1);
    xor_gate xor2 (w1, cin, sum);
    
    and_gate and1 (a, b, w2);
    and_gate and2 (w1, cin, w3);
    or_gate or1 (w2, w3, cout);
endmodule

// 5-bit 2-to-1 Multiplexer
module mux_5bit (
    input [4:0] a,
    input [4:0] b,
    input sel,
    output [4:0] y
);
    mux_1bit mux0 (.a(a[0]), .b(b[0]), .sel(sel), .y(y[0]));
    mux_1bit mux1 (.a(a[1]), .b(b[1]), .sel(sel), .y(y[1]));
    mux_1bit mux2 (.a(a[2]), .b(b[2]), .sel(sel), .y(y[2]));
    mux_1bit mux3 (.a(a[3]), .b(b[3]), .sel(sel), .y(y[3]));
    mux_1bit mux4 (.a(a[4]), .b(b[4]), .sel(sel), .y(y[4]));
endmodule

// 1-bit 2-to-1 Multiplexer
module mux_1bit (
    input a,
    input b,
    input sel,
    output y
);
    wire w1, w2, not_sel;
    
    not_gate not1 (sel, not_sel);
    and_gate and1 (a, not_sel, w1);
    and_gate and2 (b, sel, w2);
    or_gate or1 (w1, w2, y);
endmodule

// Basic logic gates
module and_gate (input a, input b, output y);
    and(y,a,b);
endmodule

module or_gate (input a, input b, output y);
    or(y,a,b);
endmodule

module xor_gate (input a, input b, output y);
    xor(y,a,b);
endmodule

module not_gate (input a, output y);
    not(y,a);
endmodule


module Mod512Counter (
    input sensor,
    input[4:0]date,
    input reset,
    output reg [9:0] units_cons
);
    always @(posedge sensor or posedge reset) begin
        if (reset | date == 5'd1)
            units_cons <= 10'd0;
        else
            units_cons <= (units_cons == 10'd512) ? 10'd0 : units_cons + 1'd1;
    end
endmodule

module comparator1(
    input [9:0] units_cons,
    output F
);
    // FREE_LIMIT = 50 (0000110010 in binary)
    wire [9:0] free_limit;
    buf(free_limit[0], 1'b0);
    buf(free_limit[1], 1'b1);
    buf(free_limit[2], 1'b0);
    buf(free_limit[3], 1'b0);
    buf(free_limit[4], 1'b1);
    buf(free_limit[5], 1'b1);
    buf(free_limit[6], 1'b0);
    buf(free_limit[7], 1'b0);
    buf(free_limit[8], 1'b0);
    buf(free_limit[9], 1'b0);

    // Implement 10-bit "greater than" comparison
    wire [9:0] gt, eq;
    wire [9:0] gt_cascade;

    // Generate bit-wise comparisons
    xnor(eq[9], units_cons[9], free_limit[9]);
    and(gt[9], units_cons[9], ~free_limit[9]);

    xnor(eq[8], units_cons[8], free_limit[8]);
    and(gt[8], units_cons[8], ~free_limit[8]);

    xnor(eq[7], units_cons[7], free_limit[7]);
    and(gt[7], units_cons[7], ~free_limit[7]);

    xnor(eq[6], units_cons[6], free_limit[6]);
    and(gt[6], units_cons[6], ~free_limit[6]);

    xnor(eq[5], units_cons[5], free_limit[5]);
    and(gt[5], units_cons[5], ~free_limit[5]);

    xnor(eq[4], units_cons[4], free_limit[4]);
    and(gt[4], units_cons[4], ~free_limit[4]);

    xnor(eq[3], units_cons[3], free_limit[3]);
    and(gt[3], units_cons[3], ~free_limit[3]);

    xnor(eq[2], units_cons[2], free_limit[2]);
    and(gt[2], units_cons[2], ~free_limit[2]);

    xnor(eq[1], units_cons[1], free_limit[1]);
    and(gt[1], units_cons[1], ~free_limit[1]);

    xnor(eq[0], units_cons[0], free_limit[0]);
    and(gt[0], units_cons[0], ~free_limit[0]);

    // Cascade the greater than comparisons
    buf(gt_cascade[9], gt[9]);
    or(gt_cascade[8], gt[9], gt[8]);
    or(gt_cascade[7], gt_cascade[8], gt[7]);
    or(gt_cascade[6], gt_cascade[7], gt[6]);
    or(gt_cascade[5], gt_cascade[6], gt[5]);
    or(gt_cascade[4], gt_cascade[5], gt[4]);
    or(gt_cascade[3], gt_cascade[4], gt[3]);
    or(gt_cascade[2], gt_cascade[3], gt[2]);
    or(gt_cascade[1], gt_cascade[2], gt[1]);
    or(gt_cascade[0], gt_cascade[1], gt[0]);

    // Final output
    buf(F, gt_cascade[0]);

endmodule

//Module to get no.of units consumed in range 1
   /*key:-
     units_aft_fl = units consumed after free limit
     units_out = units consumed in range 1
     ll = lower limit of range 1 = 1 unit
     ul = upper limit of range 1 = 50 units*/
module range1(
    input [9:0] units_aft_fl,
    output [9:0] units_out,
    output next
);
    // Constants
    wire [9:0] ll, ul, inactive;
    
    // ll = 1 (0000000001 in binary)
    buf(ll[0], 1'b1);
    buf(ll[1], 1'b0);
    buf(ll[2], 1'b0);
    buf(ll[3], 1'b0);
    buf(ll[4], 1'b0);
    buf(ll[5], 1'b0);
    buf(ll[6], 1'b0);
    buf(ll[7], 1'b0);
    buf(ll[8], 1'b0);
    buf(ll[9], 1'b0);

    // ul = 50 (0000110010 in binary)
    buf(ul[0], 1'b0);
    buf(ul[1], 1'b1);
    buf(ul[2], 1'b0);
    buf(ul[3], 1'b0);
    buf(ul[4], 1'b1);
    buf(ul[5], 1'b1);
    buf(ul[6], 1'b0);
    buf(ul[7], 1'b0);
    buf(ul[8], 1'b0);
    buf(ul[9], 1'b0);

    // inactive = 0 (0000000000 in binary)
    buf(inactive[0], 1'b0);
    buf(inactive[1], 1'b0);
    buf(inactive[2], 1'b0);
    buf(inactive[3], 1'b0);
    buf(inactive[4], 1'b0);
    buf(inactive[5], 1'b0);
    buf(inactive[6], 1'b0);
    buf(inactive[7], 1'b0);
    buf(inactive[8], 1'b0);
    buf(inactive[9], 1'b0);

    // A = units_aft_fl >= ll
    wire A;
    wire [9:0] ge_ll;
    greater_than_or_equal_10bit ge_ll_comp(
        .a(units_aft_fl),
        .b(ll),
        .ge(A)
    );

    // B = units_aft_fl <= ul
    wire B;
    wire [9:0] le_ul;
    less_than_or_equal_10bit le_ul_comp(
        .a(units_aft_fl),
        .b(ul),
        .le(B)
    );

    // next = ~B
    not(next, B);

    // if(A && B) units_out = units_aft_fl;
    // else if(~A) units_out = inactive;
    // else units_out = ul;
    wire A_and_B, not_A;
    and(A_and_B, A, B);
    not(not_A, A);

    wire [9:0] temp_out;
    mux_10bit mux1(
        .a(units_aft_fl),
        .b(inactive),
        .sel(A_and_B),
        .y(temp_out)
    );

    mux_10bit mux2(
        .a(ul),
        .b(temp_out),
        .sel(not_A),
        .y(units_out)
    );

endmodule

// 10-bit Greater Than or Equal comparator
module greater_than_or_equal_10bit(
    input [9:0] a,
    input [9:0] b,
    output ge
);
    wire [9:0] gt, eq;
    wire [9:0] ge_cascade;

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gen_compare
            xnor(eq[i], a[i], b[i]);
            and(gt[i], a[i], ~b[i]);
        end
    endgenerate

    buf(ge_cascade[9], gt[9]);
    or(ge_cascade[8], gt[8], ge_cascade[9]);
    or(ge_cascade[7], gt[7], ge_cascade[8]);
    or(ge_cascade[6], gt[6], ge_cascade[7]);
    or(ge_cascade[5], gt[5], ge_cascade[6]);
    or(ge_cascade[4], gt[4], ge_cascade[5]);
    or(ge_cascade[3], gt[3], ge_cascade[4]);
    or(ge_cascade[2], gt[2], ge_cascade[3]);
    or(ge_cascade[1], gt[1], ge_cascade[2]);
    or(ge_cascade[0], gt[0], ge_cascade[1]);

    or(ge, ge_cascade[0], eq[0]);
endmodule

// 10-bit 2-to-1 Multiplexer
module mux_10bit(
    input [9:0] a,
    input [9:0] b,
    input sel,
    output [9:0] y
);
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gen_mux
            wire w1, w2, not_sel;
            not(not_sel, sel);
            and(w1, a[i], not_sel);
            and(w2, b[i], sel);
            or(y[i], w1, w2);
        end
    endgenerate
endmodule


//Module to get no.of units consumed in range 2
   /*key:-
     units_aft_fl = units consumed after free limit
     units_out = units consumed in range 2
     ul1 = upper limit of range 1 = 50 units
     ul2 = upper limit of range 2 = 150 units
     tot_units = total units in range 2
     prev = input from range 1 indicating if units consumed is greater than range 1 or not*/
module range2(
    input [9:0] units_aft_fl,
    input prev,
    output [9:0] units_out,
    output next
);
    // Constants
    wire [9:0] ul1, ul2, tot_units, inactive;
    
    // ul1 = 50 (0000110010 in binary)
    buf(ul1[0], 1'b0);
    buf(ul1[1], 1'b1);
    buf(ul1[2], 1'b0);
    buf(ul1[3], 1'b0);
    buf(ul1[4], 1'b1);
    buf(ul1[5], 1'b1);
    buf(ul1[6], 1'b0);
    buf(ul1[7], 1'b0);
    buf(ul1[8], 1'b0);
    buf(ul1[9], 1'b0);

    // ul2 = 150 (0010010110 in binary)
    buf(ul2[0], 1'b0);
    buf(ul2[1], 1'b1);
    buf(ul2[2], 1'b1);
    buf(ul2[3], 1'b0);
    buf(ul2[4], 1'b1);
    buf(ul2[5], 1'b0);
    buf(ul2[6], 1'b0);
    buf(ul2[7], 1'b1);
    buf(ul2[8], 1'b0);
    buf(ul2[9], 1'b0);

    // tot_units = 100 (0001100100 in binary)
    buf(tot_units[0], 1'b0);
    buf(tot_units[1], 1'b0);
    buf(tot_units[2], 1'b1);
    buf(tot_units[3], 1'b0);
    buf(tot_units[4], 1'b0);
    buf(tot_units[5], 1'b1);
    buf(tot_units[6], 1'b1);
    buf(tot_units[7], 1'b0);
    buf(tot_units[8], 1'b0);
    buf(tot_units[9], 1'b0);

    // inactive = 0 (0000000000 in binary)
    buf(inactive[0], 1'b0);
    buf(inactive[1], 1'b0);
    buf(inactive[2], 1'b0);
    buf(inactive[3], 1'b0);
    buf(inactive[4], 1'b0);
    buf(inactive[5], 1'b0);
    buf(inactive[6], 1'b0);
    buf(inactive[7], 1'b0);
    buf(inactive[8], 1'b0);
    buf(inactive[9], 1'b0);

    // A = units_aft_fl <= ul2
    wire A;
    less_than_or_equal_10bit le_ul2_comp(
        .a(units_aft_fl),
        .b(ul2),
        .le(A)
    );

    // next = prev & ~A
    wire not_A;
    not(not_A, A);
    and(next, prev, not_A);

    // Subtractor for units_aft_fl - ul1
    wire [9:0] subtracted_out;
    subtractor_10bit sub(
        .a(units_aft_fl),
        .b(ul1),
        .diff(subtracted_out)
    );

    // if(A) temp_out = subtracted_out; else temp_out = tot_units;
    wire [9:0] temp_out;
    mux_10bit mux1(
        .a(subtracted_out),
        .b(tot_units),
        .sel(A),
        .y(temp_out)
    );

    // if(prev) units_out = temp_out; else units_out = inactive;
    mux_10bit mux2(
        .a(temp_out),
        .b(inactive),
        .sel(prev),
        .y(units_out)
    );

endmodule

// 10-bit Less Than or Equal comparator
module less_than_or_equal_10bit(
    input [9:0] a,
    input [9:0] b,
    output le
);
    wire [9:0] lt, eq;
    wire [9:0] le_cascade;

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gen_compare
            xnor(eq[i], a[i], b[i]);
            and(lt[i], ~a[i], b[i]);
        end
    endgenerate

    buf(le_cascade[9], lt[9]);
    or(le_cascade[8], lt[8], le_cascade[9]);
    or(le_cascade[7], lt[7], le_cascade[8]);
    or(le_cascade[6], lt[6], le_cascade[7]);
    or(le_cascade[5], lt[5], le_cascade[6]);
    or(le_cascade[4], lt[4], le_cascade[5]);
    or(le_cascade[3], lt[3], le_cascade[4]);
    or(le_cascade[2], lt[2], le_cascade[3]);
    or(le_cascade[1], lt[1], le_cascade[2]);
    or(le_cascade[0], lt[0], le_cascade[1]);

    or(le, le_cascade[0], eq[0]);
endmodule

// 10-bit Subtractor
module subtractor_10bit(
    input [9:0] a,
    input [9:0] b,
    output [9:0] diff
);
    wire [10:0] borrow;
    buf(borrow[0], 1'b0);

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gen_sub
            wire diff_i, borrow_out;
            xor(diff_i, a[i], b[i], borrow[i]);
            and(borrow_out, ~a[i], b[i]);  
            or(borrow[i+1], borrow_out, ( ~a[i] & borrow[i] ));
            buf(diff[i], diff_i);
        end
    endgenerate
endmodule

//Module to get no.of units consumed in range 3
    /*key:-
      units_aft_fl = units consumed after free limit
      units_out = units consumed in range 2
      ul1 = upper limit of range 2 = 150 units
      prev = input from range 2 indicating if units consumed is greater than range 2 or not*/
module range3(
    input [9:0] units_aft_fl,
    input prev,
    output [9:0] units_out
);

    // Constants
    wire [9:0] ul;
    wire [9:0] inactive;

    // Hardcoding ul (150 in binary) using AND gates with 1
    and(ul[0], 1'b0, 1'b1);
    and(ul[1], 1'b1, 1'b1);
    and(ul[2], 1'b1, 1'b1);
    and(ul[3], 1'b0, 1'b1);
    and(ul[4], 1'b1, 1'b1);
    and(ul[5], 1'b0, 1'b1);
    and(ul[6], 1'b0, 1'b1);
    and(ul[7], 1'b1, 1'b1);
    and(ul[8], 1'b0, 1'b1);
    and(ul[9], 1'b0, 1'b1);

    // Hardcoding inactive (all zeros) using AND gates with 0
    and(inactive[0], 1'b0, 1'b1);
    and(inactive[1], 1'b0, 1'b1);
    and(inactive[2], 1'b0, 1'b1);
    and(inactive[3], 1'b0, 1'b1);
    and(inactive[4], 1'b0, 1'b1);
    and(inactive[5], 1'b0, 1'b1);
    and(inactive[6], 1'b0, 1'b1);
    and(inactive[7], 1'b0, 1'b1);
    and(inactive[8], 1'b0, 1'b1);
    and(inactive[9], 1'b0, 1'b1);

    // Subtraction using full subtractors
    wire [10:0] borrow;
    and(borrow[0], 1'b0, 1'b1); // Initial borrow is 0

    // Instantiate 10 full subtractors
    full_subtractor fs0 (.a(units_aft_fl[0]), .b(ul[0]), .bin(borrow[0]), .diff(units_out[0]), .bout(borrow[1]));
    full_subtractor fs1 (.a(units_aft_fl[1]), .b(ul[1]), .bin(borrow[1]), .diff(units_out[1]), .bout(borrow[2]));
    full_subtractor fs2 (.a(units_aft_fl[2]), .b(ul[2]), .bin(borrow[2]), .diff(units_out[2]), .bout(borrow[3]));
    full_subtractor fs3 (.a(units_aft_fl[3]), .b(ul[3]), .bin(borrow[3]), .diff(units_out[3]), .bout(borrow[4]));
    full_subtractor fs4 (.a(units_aft_fl[4]), .b(ul[4]), .bin(borrow[4]), .diff(units_out[4]), .bout(borrow[5]));
    full_subtractor fs5 (.a(units_aft_fl[5]), .b(ul[5]), .bin(borrow[5]), .diff(units_out[5]), .bout(borrow[6]));
    full_subtractor fs6 (.a(units_aft_fl[6]), .b(ul[6]), .bin(borrow[6]), .diff(units_out[6]), .bout(borrow[7]));
    full_subtractor fs7 (.a(units_aft_fl[7]), .b(ul[7]), .bin(borrow[7]), .diff(units_out[7]), .bout(borrow[8]));
    full_subtractor fs8 (.a(units_aft_fl[8]), .b(ul[8]), .bin(borrow[8]), .diff(units_out[8]), .bout(borrow[9]));
    full_subtractor fs9 (.a(units_aft_fl[9]), .b(ul[9]), .bin(borrow[9]), .diff(units_out[9]), .bout(borrow[10]));

    // Multiplexer to select between subtraction result and inactive based on prev
    mux2to1_10bit mux (
        .a(inactive),
        .b({units_out[9], units_out[8], units_out[7], units_out[6], units_out[5], 
            units_out[4], units_out[3], units_out[2], units_out[1], units_out[0]}),
        .sel(prev),
        .y(units_out)
    );

endmodule

//Module to get total price for units consumed in range 2
module mul2 (
    input [9:0] units_out,
    output [9:0] cost_cons_in_r2
);

    // Hardcode price = 2 (10 in binary)
    wire price0, price1;
    and(price0, 1'b0, 1'b1);
    and(price1, 1'b1, 1'b1);

    // Generate partial products
    wire [9:0] partial_product0, partial_product1;
    
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gen_partial_products
            and(partial_product0[i], units_out[i], price0);
            and(partial_product1[i], units_out[i], price1);
        end
    endgenerate

    // Add partial products (effectively shifting partial_product1 left by 1 bit)
    wire [9:0] sum;
    wire [10:0] carry;

    // First bit
    and(sum[0], partial_product0[0], 1'b1);
    and(carry[0], 1'b0, 1'b1);

    // Remaining bits
    genvar j;
    generate
        for (j = 1; j < 10; j = j + 1) begin : gen_addition
            wire sum_temp;
            full_adder fa (
                .a(partial_product0[j]),
                .b(partial_product1[j-1]),
                .cin(carry[j-1]),
                .sum(sum_temp),
                .cout(carry[j])
            );
            and(sum[j], sum_temp, 1'b1);
        end
    endgenerate

    // Final output
    and(cost_cons_in_r2[0], sum[0], 1'b1);
    and(cost_cons_in_r2[1], sum[1], 1'b1);
    and(cost_cons_in_r2[2], sum[2], 1'b1);
    and(cost_cons_in_r2[3], sum[3], 1'b1);
    and(cost_cons_in_r2[4], sum[4], 1'b1);
    and(cost_cons_in_r2[5], sum[5], 1'b1);
    and(cost_cons_in_r2[6], sum[6], 1'b1);
    and(cost_cons_in_r2[7], sum[7], 1'b1);
    and(cost_cons_in_r2[8], sum[8], 1'b1);
    and(cost_cons_in_r2[9], sum[9], 1'b1);

endmodule

//Module to get total price for units consumed in range 3
module mul3 (
    input [9:0] units_out,
    output [9:0] cost_cons_in_r3
);

    // Hardcode price = 3 (11 in binary)
    wire price0, price1;
    and(price0, 1'b1, 1'b1);
    and(price1, 1'b1, 1'b1);

    // Generate partial products
    wire [9:0] partial_product0, partial_product1;
    
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : gen_partial_products
            and(partial_product0[i], units_out[i], price0);
            and(partial_product1[i], units_out[i], price1);
        end
    endgenerate

    // Add partial products (effectively shifting partial_product1 left by 1 bit)
    wire [9:0] sum;
    wire [10:0] carry;

    // First bit
    and(sum[0], partial_product0[0], 1'b1);
    and(carry[0], 1'b0, 1'b1);

    // Remaining bits
    genvar j;
    generate
        for (j = 1; j < 10; j = j + 1) begin : gen_addition
            wire sum_temp;
            full_adder fa (
                .a(partial_product0[j]),
                .b(partial_product1[j-1]),
                .cin(carry[j-1]),
                .sum(sum_temp),
                .cout(carry[j])
            );
            and(sum[j], sum_temp, 1'b1);
        end
    endgenerate

    // Final output
    and(cost_cons_in_r3[0], sum[0], 1'b1);
    and(cost_cons_in_r3[1], sum[1], 1'b1);
    and(cost_cons_in_r3[2], sum[2], 1'b1);
    and(cost_cons_in_r3[3], sum[3], 1'b1);
    and(cost_cons_in_r3[4], sum[4], 1'b1);
    and(cost_cons_in_r3[5], sum[5], 1'b1);
    and(cost_cons_in_r3[6], sum[6], 1'b1);
    and(cost_cons_in_r3[7], sum[7], 1'b1);
    and(cost_cons_in_r3[8], sum[8], 1'b1);
    and(cost_cons_in_r3[9], sum[9], 1'b1);

endmodule

//Module to get total price consumed
module price_adder(
    input [9:0] R1,
    input [9:0] R2,
    input [9:0] R3,
    output [9:0] tot_cost_cons
);

    wire [9:0] sum_R1_R2;
    wire carry_R1_R2;

    // First 10-bit adder: R1 + R2
    adder_10bit adder1 (
        .a(R1),
        .b(R2),
        .sum(sum_R1_R2),
        .carry_out(carry_R1_R2)
    );

    wire carry_final;

    // Second 10-bit adder: (R1 + R2) + R3
    adder_10bit adder2 (
        .a(sum_R1_R2),
        .b(R3),
        .sum(tot_cost_cons),
        .carry_out(carry_final)
    );

    // Note: carry_final is ignored as the output is limited to 10 bits

endmodule

// 10-bit adder
module adder_10bit(
    input [9:0] a,
    input [9:0] b,
    output [9:0] sum,
    output carry_out
);
    wire [10:0] carry;
    assign carry[0] = 0;

    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : add_loop
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .cin(carry[i]),
                .sum(sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    assign carry_out = carry[10];
endmodule

//Subtractor Module to find balance amount from prepaid amount
module subtractor_balance(
    input [9:0] prepaid,
    input [9:0] tot_cost_cons,
    output [9:0] balance
);

    wire [9:0] subtraction_result;
    wire borrow_out;

    // 10-bit subtractor
    subtractor_10bit sub (
        .a(prepaid),
        .b(tot_cost_cons),
        .diff(subtraction_result),
        .borrow_out(borrow_out)
    );

    // Multiplexer to select between subtraction result and 0
    mux2to1_10bit mux (
        .a(subtraction_result),
        .b(10'b0000000000),
        .sel(borrow_out),
        .y(balance)
    );

endmodule

//comparator for alerts
module alert(
    input [9:0] balance,
    output alert1,
    output alert2
);

    // Hardcode danger_lvl = 45 (101101 in binary)
    wire [9:0] danger_lvl;
    wire constant_1 = 1'b1;
    wire constant_0 = 1'b0;

    buf(danger_lvl[0], constant_1);
    buf(danger_lvl[1], constant_0);
    buf(danger_lvl[2], constant_1);
    buf(danger_lvl[3], constant_1);
    buf(danger_lvl[4], constant_0);
    buf(danger_lvl[5], constant_1);
    buf(danger_lvl[6], constant_0);
    buf(danger_lvl[7], constant_0);
    buf(danger_lvl[8], constant_0);
    buf(danger_lvl[9], constant_0);


    // Comparator for balance <= danger_lvl
    wire [9:0] sub_result;
    wire borrow;
    subtractor_10bit sub (
        .a(balance),
        .b(danger_lvl),
        .diff(sub_result),
        .borrow_out(borrow)
    );

    // alert1 is high if balance <= danger_lvl (borrow is high)
    buf (alert1, borrow);
   

    // alert2 is high if balance == 0
    wire balance_is_zero;
    nor(balance_is_zero, balance[0], balance[1], balance[2], balance[3], balance[4],
                         balance[5], balance[6], balance[7], balance[8], balance[9]);
   buf (alert2, balance_zero);

endmodule

// Full Subtractor
module full_subtractor(
    input a,
    input b,
    input bin,
    output diff,
    output bout
);
    wire w1, w2, w3;
    
    xor(w1, a, b);
    xor(diff, w1, bin);
    
    not(w2, a);
    and(w3, w2, b);
    and(w4, w2, bin);
    and(w5, b, bin);
    or(bout, w3, w4, w5);
endmodule

//Module to find approximate Average consumption per day
module find_avg(
    input [9:0] tot_cost_cons,
    input [4:0] date,
    input clk,  // Added clock input for sequential logic
    input reset,  // Added reset input
    output [9:0] avg_per_day
);

    wire is_zero;
    wire [9:0] division_result;
    wire division_done;

    // Check if date is zero
    nor(is_zero, date[0], date[1], date[2], date[3], date[4]);

    // Divider module
    divider div (
        .clk(clk),
        .reset(reset),
        .dividend(tot_cost_cons),
        .divisor({5'b0, date}),  // Zero-extend date to 10 bits
        .quotient(division_result),
        .done(division_done)
    );

    // Multiplexer to select between division result and tot_cost_cons
    mux2to1_10bit mux (
        .a(division_result),
        .b(tot_cost_cons),
        .sel(is_zero),
        .y(avg_per_day)
    );

endmodule

//approximately how many more days will the plan last
module days_lasting(
    input [9:0] balance,
    input [9:0] avg_per_day,
    input clk,  // Added clock input for sequential logic
    input reset,  // Added reset input
    output [9:0] days_lasting
);

    wire is_zero;
    wire [9:0] division_result;
    wire division_done;

    // Check if avg_per_day is zero
    nor(is_zero, avg_per_day[0], avg_per_day[1], avg_per_day[2], avg_per_day[3], avg_per_day[4], 
               avg_per_day[5], avg_per_day[6], avg_per_day[7], avg_per_day[8], avg_per_day[9]);

    // Divider module
    divider div (
        .clk(clk),
        .reset(reset),
        .dividend(balance),
        .divisor(avg_per_day),
        .quotient(division_result),
        .done(division_done)
    );

    // Multiplexer to select between division result and 365
    mux2to1_10bit mux (
        .a(division_result),
        .b(10'd365),
        .sel(is_zero),
        .y(days_lasting)
    );

endmodule

// 10-bit divider module
module divider(
    input clk,
    input reset,
    input [9:0] dividend,
    input [9:0] divisor,
    output reg [9:0] quotient,
    output reg done
);
    reg [9:0] temp_dividend;
    reg [3:0] count;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            temp_dividend <= 0;
            quotient <= 0;
            count <= 0;
            done <= 0;
        end else begin
            if (!done) begin
                if (count == 0) begin
                    temp_dividend <= dividend;
                    count <= count + 1;
                end else if (count <= 10) begin
                    if (temp_dividend >= divisor) begin
                        temp_dividend <= temp_dividend - divisor;
                        quotient <= (quotient << 1) | 1'b1;
                    end else begin
                        quotient <= quotient << 1;
                    end
                    temp_dividend <= temp_dividend << 1;
                    count <= count + 1;
                end else begin
                    done <= 1;
                end
            end
        end
    end
endmodule

// 2-to-1 Multiplexer for 10-bit inputs
module mux2to1_10bit(
    input [9:0] a, b,
    input sel,
    output [9:0] y
);
    genvar i;
    generate
        for (i = 0; i < 10; i = i + 1) begin : mux_gen
            mux2to1 mux_inst (.a(a[i]), .b(b[i]), .sel(sel), .y(y[i]));
        end
    endgenerate
endmodule

// 2-to-1 Multiplexer for 1-bit
module mux2to1(
    input a, b, sel,
    output y
);
    wire w1, w2, not_sel;
    
    not(not_sel, sel);
    and(w1, a, not_sel);
    and(w2, b, sel);
    or(y, w1, w2);
endmodule

//MAIN MODULE
module main(
    input sensor, date_1, reset,
    input [9:0] prepaid,
    output wire [9:0] balance, avg_per_day,days_lasting,units_cons,
    output wire alert1, alert2,
    output[4:0] date
);
    wire F;
    wire next1, next2;
    wire [9:0] units_aft_fl, units_out1, units_out2, units_out3;// units_aft_fl = units consumed after free limit
                                                                // units_out = units consumed in respective ranges

    wire [9:0] cost_cons_in_r2, cost_cons_in_r3, tot_cost_cons;
    wire [4:0] date;

    date_counter dut_date(date_1, reset, date);
    Mod512Counter dut1(sensor, date, reset, units_cons); // this is keep a track how of much electricity is consumed 
                                                         // the sensor resets to 0 when date is 31 or reset is 1

    comparator1 dut2(units_cons, F);                     // checks wheter it has crossed the free limit
    subtractor_10bit dut3(units_cons, F, units_aft_fl);  // if F=0 then sub is inactive else gives the extra amount
    range1 dut4(units_aft_fl, units_out1, next1);
    range2 dut5(units_aft_fl, next1, units_out2, next2);
    range3 dut6(units_aft_fl, next2, units_out3);
    mul2 dut7(units_out2, cost_cons_in_r2);             // multiplies the units consumed * the price for range 2
    mul3 dut8(units_out3, cost_cons_in_r3);             // multiplies the units consumed * the price for range 3
    price_adder dut9(units_out1, cost_cons_in_r2, cost_cons_in_r3, tot_cost_cons);
    subtractor_balance dut10(prepaid, tot_cost_cons, balance);  // output
    alert dut11(balance, alert1, alert2);                       // output
    find_avg dut12(tot_cost_cons, date, sensor, sensor, avg_per_day);           // output
    days_lasting dut13(balance, avg_per_day, sensor, sensor, days_lasting);     // output
endmodule

