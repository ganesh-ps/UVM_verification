//=====================================================================
// Project: 4 core MESI cache design
// File Name: cpu_lv1_interface.sv
// Description: Basic CPU-LV1 interface with assertions
// Designers: Venky & Suru
//=====================================================================


interface cpu_lv1_interface(input clk);

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter DATA_WID_LV1           = `DATA_WID_LV1       ;
    parameter ADDR_WID_LV1           = `ADDR_WID_LV1       ;

    reg   [DATA_WID_LV1 - 1   : 0] data_bus_cpu_lv1_reg    ;

    wire  [DATA_WID_LV1 - 1   : 0] data_bus_cpu_lv1        ;
    logic [ADDR_WID_LV1 - 1   : 0] addr_bus_cpu_lv1        ;
    logic                          cpu_rd                  ;
    logic                          cpu_wr                  ;
    logic                          cpu_wr_done             ;
    logic                          data_in_bus_cpu_lv1     ;

    assign data_bus_cpu_lv1 = data_bus_cpu_lv1_reg ;

//Assertions
//ASSERTION1: cpu_wr and cpu_rd should not be asserted at the same clock cycle
    property prop_simult_cpu_wr_rd;
        @(posedge clk)
          not(cpu_rd && cpu_wr);
    endproperty

    assert_simult_cpu_wr_rd: assert property (prop_simult_cpu_wr_rd)
    else
        `uvm_error("cpu_lv1_interface",$sformatf("Assertion assert_simult_cpu_wr_rd Failed: cpu_wr and cpu_rd asserted simultaneously"))

//TODO: Add assertions at this interface

    property prop_cpu_wr_wr_done;
    @(posedge clk)
        cpu_wr |-> ##[1:$]cpu_wr_done;
    endproperty

    assert_cpu_wr_wr_done: assert property (prop_cpu_wr_wr_done)
    else
        `uvm_error("cpu_lv1_interface",$sformatf("Assertion assert_cpu_wr_wr_done Failed: cpu_wr_done not asserted after cpu_wr has been asserted"))


//ASSERTION3:Data should be read on data_bus after cpu_rd was asserted
    property prop_cpu_rd_data_bus;
        @(posedge clk)
        cpu_rd |-> ##[1:$](|data_bus_cpu_lv1);
    endproperty

    assert_cpu_rd_data_bus: assert property (prop_cpu_rd_data_bus)
    else
        `uvm_error("cpu_lv1_interface",$sformatf("Assertion assert_cpu_rd_data_bus Failed: Data not read after cpu_rd was asserted"))


//ASSERTION4:data_in_bus_cpu_lv1 should be asserted after cpu_rd was asserted
    property prop_cpu_rd_data_in_bus;
        @(posedge clk)
        cpu_rd |-> ##[1:$]data_in_bus_cpu_lv1;
    endproperty

    assert_cpu_rd_data_in_bus: assert property (prop_cpu_rd_data_in_bus)
    else
        `uvm_error("cpu_lv1_interface",$sformatf("Assertion assert_cpu_rd_data_in_bus Failed: data_in_bus_cpu_lv1 not asserted after cpu_rd was asserted"))

//ASSERTION5:Data should be read on data bus after data_in_bus_cpu_lv1 was asserted
    property prop_cpu_data_in_bus_data_bus;
        @(posedge clk)
        data_in_bus_cpu_lv1 |-> (|data_bus_cpu_lv1);
    endproperty
    
    assert_cpu_data_in_bus: assert property (prop_cpu_data_in_bus_data_bus)
    else
        `uvm_error("cpu_lv1_interface",$sformatf("Assertion assert_cpu_data_in_bus_data_bus Failed: No Data not read on data bus after data_in_bus_cpu_lv1 was asserted"))

endinterface

