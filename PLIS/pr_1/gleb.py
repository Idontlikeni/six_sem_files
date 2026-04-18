msgs = [
    "RESult:", "ERR: fOrMAt datA", "eRR:paRItY UArT", "eRR- fORMat DAtA UarT",
    "errOr- uarT"
]
address_count = 0
for msg in msgs:
    address_count += len(msg)

address_width = (address_count-1).bit_length()
current_address = 0
for msg in msgs:
    print(f"Start Address: {current_address:0{address_width}b}")
    print(f"End Address: {(current_address + len(msg)-1):0{address_width}b}")
    print()
    for index in range(len(msg)):
        print(f"{current_address:0{address_width}b}: \"{msg[index]}\" => 0x{ord(msg[index]):02X}")
        current_address += 1
    print()

[print(f"{ord(c):02X}") for msg in msgs for c in msg]
