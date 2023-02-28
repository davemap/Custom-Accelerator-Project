## status_regs

* byte_size
    * 16

|name|offset_address|
|:--|:--|
|[status_0](#status_regs-status_0)|0x0|

### <div id="status_regs-status_0"></div>status_0

* offset_address
    * 0x0
* type
    * default

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|status_id|[5:0]|ro|0x00|||Contains last ID Value in ID Buffer|
|status_buffered_ids|[8:6]|ro|0x0|||Number of IDs in ID Buffer|
|status_err_buffer|[9]|ro|0x0|||ID Buffer Error|
|status_err_packet|[10]|ro|0x0|||Dropped Packet Error|
|status_err_clear|[11]|wo|0x0|||Clear Error Flags|
|status_packet_count|[21:12]|ro|0x000|||Number of Packets Passed Through|
