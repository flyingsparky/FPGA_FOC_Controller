#Setting
#Kp
create_hw_axi_txn -force write_txn [get_hw_axis hw_axi_1] -type write -address 4000_0000 -len 1 -data 0002_f000
run_hw_axi [get_hw_axi_txns write_txn]

create_hw_axi_txn -force read_txn [get_hw_axis hw_axi_1] -type read -address 4000_0000 -len 1
run_hw_axi [get_hw_axi_txns read_txn]

#Ki
create_hw_axi_txn -force write_txn [get_hw_axis hw_axi_1] -type write -address 4001_0000 -len 1 -data 0000_3000
run_hw_axi [get_hw_axi_txns write_txn]

create_hw_axi_txn -force read_txn [get_hw_axis hw_axi_1] -type read -address 4001_0000 -len 1
run_hw_axi [get_hw_axi_txns read_txn]

#Resetting
#Kp
create_hw_axi_txn -force write_txn [get_hw_axis hw_axi_1] -type write -address 4000_0000 -len 1 -data 0000_0000
run_hw_axi [get_hw_axi_txns write_txn]

create_hw_axi_txn -force read_txn [get_hw_axis hw_axi_1] -type read -address 4000_0000 -len 1
run_hw_axi [get_hw_axi_txns read_txn]

#Ki
create_hw_axi_txn -force write_txn [get_hw_axis hw_axi_1] -type write -address 4001_0000 -len 1 -data 0000_0000
run_hw_axi [get_hw_axi_txns write_txn]

create_hw_axi_txn -force read_txn [get_hw_axis hw_axi_1] -type read -address 4001_0000 -len 1
run_hw_axi [get_hw_axi_txns read_txn]
