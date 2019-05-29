//=====================================================================
// Project: 4 core MESI cache design
// File Name: cpu_mesi_lru_interface.sv
// Description: MESI LRU Interface
// Designers: 
//=====================================================================

interface cpu_mesi_lru_interface(input clk);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter MESI_WID = `MESI_WID_LV1         ;
    parameter ASSOC_WID   = `ASSOC_WID_LV1     ;
    parameter INDEX_MSB   = `INDEX_MSB_LV1     ;
    parameter INDEX_LSB   = `INDEX_LSB_LV1     ;
    parameter LRU_VAR_WID = `LRU_VAR_WID_LV1   ;
    parameter NUM_OF_SETS = `NUM_OF_SETS_LV1   ;
    parameter INVALID     = 2'b00              ;
    parameter SHARED      = 2'b01              ;
    parameter EXCLUSIVE   = 2'b10              ;
    parameter MODIFIED    = 2'b11              ;

    wire                         cpu_rd        ;
    wire                         cpu_wr        ;
    wire                         bus_rd        ;
    wire                         bus_rdx       ;
    wire                         invalidate    ;
    wire                         shared        ;
    wire [MESI_WID - 1 : 0] current_mesi_proc  ;
    wire [MESI_WID - 1 : 0] current_mesi_snoop ;
    wire [MESI_WID - 1 : 0] updated_mesi_proc  ;
    wire [MESI_WID - 1 : 0] updated_mesi_snoop ;

    wire [INDEX_MSB     : INDEX_LSB ] index_proc          ;
    wire [ASSOC_WID - 1 : 0         ] blk_accessed_main   ;
    wire [ASSOC_WID - 1 : 0         ] lru_replacement_proc;

//Assertions

    property modified_to_modified;
    @(posedge clk)
	$past(current_mesi_proc == MODIFIED)  && $rose(cpu_rd) |=> (updated_mesi_proc == MODIFIED);    
    endproperty

    assert_modified_to_modified: assert property(modified_to_modified)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_modified_to_modified Failed: Proc MESI state doesn't remain in Modified once cpu_rd was asserted")) 

    property exclusive_to_modified;
    @(posedge clk)
        $past(current_mesi_proc == EXCLUSIVE) && $rose(cpu_wr) |=> (updated_mesi_proc == MODIFIED);
    endproperty

    assert_exclusive_to_modified: assert property(exclusive_to_modified)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_exclusive_to_modified Failed: Proc MESI state not updated from Exclusive to Modified once cpu_wr was asserted"))

    property shared_to_modified;
    @(posedge clk)
        $past(current_mesi_proc == SHARED) && $rose(cpu_wr) |=> (updated_mesi_proc == MODIFIED);
    endproperty

    assert_shared_to_modified: assert property(shared_to_modified)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_shared_to_modified Failed: Proc MESI state not updated from Shared to Modified once cpu_wr was asserted"))

    property invalid_to_modified;
    @(posedge clk)
        $past(current_mesi_proc == INVALID) && $rose(cpu_wr) |=> (updated_mesi_proc == MODIFIED);
    endproperty

    assert_invalid_to_modified: assert property(invalid_to_modified)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_invalid_to_modified Failed: Proc MESI state not updated from Invalid to Modified once cpu_wr was asserted"))

    property exclusive_to_exclusive;
    @(posedge clk)
        $past(current_mesi_proc == EXCLUSIVE) && $rose(cpu_rd) |=> (updated_mesi_proc == EXCLUSIVE);
    endproperty

    assert_exclusive_to_exclusive: assert property(exclusive_to_exclusive)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_exclusive_to_exclusive Failed: Proc MESI state doesn't remain in  Exclusive once cpu_rd was asserted"))

    property shared_to_shared;
    @(posedge clk)
        $past(current_mesi_proc == SHARED) && $rose(cpu_rd) |=> (updated_mesi_proc == SHARED);
    endproperty

    assert_shared_to_shared: assert property(shared_to_shared)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_shared_to_shared Failed: Proc MESI state doesn't remain in Shared once cpu_rd was asserted"))
/*
    property invalid_to_exclusive;
    @(posedge clk)
        $past(current_mesi_proc == INVALID) && (!(shared) && $rose(cpu_rd)) |=> (updated_mesi_proc == EXCLUSIVE);
    endproperty

    assert_invalid_to_exclusive: assert property(invalid_to_exclusive)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_invalid_to_exclusive Failed: Proc MESI state not updated from Invalid to Exclusive once cpu_rd was asserted and shared was deasserted"))
  */  
    property invalid_to_shared;
    @(posedge clk)
        $past(current_mesi_proc == INVALID) && ((shared) && $rose(cpu_rd)) |=> (updated_mesi_proc == SHARED);
    endproperty

   assert_invalid_to_shared: assert property(invalid_to_shared)
   else
   `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_invalid_to_shared Failed: Proc MESI state not updated from Invalid to Shared once cpu_rd was asserted and shared was asserted"))
   
    property modified_to_invalid;
    @(posedge clk)
        $past(current_mesi_snoop == MODIFIED) && ($rose(bus_rdx) || $rose(invalidate)) |=> (updated_mesi_snoop == INVALID);
    endproperty

    assert_modified_to_invalid: assert property(modified_to_invalid)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_modified_to_invalid Failed: Snoop MESI state not updated from Modified to Invalid once bus_rdx was asserted or invalidate was asserted"))

    property modified_to_shared;
    @(posedge clk)
        $past(current_mesi_snoop == MODIFIED) && $rose(bus_rd) |=> (updated_mesi_snoop == SHARED);
    endproperty

    assert_modified_to_shared: assert property(modified_to_shared)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_modified_to_shared Failed: Snoop MESI state not updated from Modified to Shared once bus_rd was asserted"))

    property exclusive_to_shared;
    @(posedge clk)
        $past(current_mesi_snoop == EXCLUSIVE) && $rose(bus_rd) |=> (updated_mesi_snoop == SHARED);
    endproperty

    assert_exclusive_to_shared: assert property(exclusive_to_shared)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_exclusive_to_shared Failed: Snoop MESI state not updated from Exclusive to Shared once bus_rd was asserted"))

    property exclusive_to_invalid;
    @(posedge clk)
        $past(current_mesi_snoop == EXCLUSIVE) && ($rose(bus_rdx) || $rose(invalidate)) |=> (updated_mesi_snoop == INVALID);
    endproperty

    assert_exclusive_to_invalid: assert property(exclusive_to_invalid)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_exclusive_to_invalid Failed: Snoop MESI state not updated from Exclusive to Invalid once bus_rdx was asserted or invalidate was asserted"))

    property shared_to_invalid;
    @(posedge clk)
        $past(current_mesi_snoop == SHARED) && ($rose(bus_rdx) || $rose(invalidate)) |=> (updated_mesi_snoop == INVALID);
    endproperty

    assert_shared_to_invalid: assert property(shared_to_invalid)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_shared_to_invalid Failed: Snoop MESI state not updated from Shared to Invalid once bus_rdx was asserted or invalidate was asserted"))

    property shared_to_shared_snoop;
    @(posedge clk)
        $past(current_mesi_snoop == SHARED) && $rose(bus_rd) |=> (updated_mesi_snoop == SHARED);
    endproperty

    assert_shared_to_shared_snoop: assert property(shared_to_shared_snoop)
    else
    `uvm_error("cpu_mesi_lru_interface",$sformatf("Assertion assert_shared_to_shared_snoop Failed: Snoop MESI state doesn't stay in Shared state once bus_rd was asserted"))

endinterface


