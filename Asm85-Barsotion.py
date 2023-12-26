
# Ассемблерный транслятор Asm85_Barsotion
# Версия 1.2. Дата обновления - 26.12.22!
# Версия 1.3. Дата обновления - 05.02.23! (добавлена поддержка недокументированных инструкций 8085)
# Версия 1.4. Дата обновления - 11.07.23! (добавлена шпаргалка по использованию софта)
#
# Как его использовать?
#
#   .def const8bit =  $78   ;
#   .def const16bit = $1234 ;
#   .db $78                 ; one byte in memory
#   .dw $1234               ; two bytes in memory, Little Endian
#   .ds 'Barsotion'         ; string in memory
#   ;                       ; it is an your comment
#   m1:                     ; it is an address pointer
#   .org $1200              ; it is an operator to pass any memories before address
#   .include 'GRLIB.asm'    ; you can include files

# All of the commands of 8085 are supported, including undocumented instructions
# such as 'DSUB', 'ARHL', 'RDEL', 'LDHI', LDSI', 'RSTV', 'SHLX', 'LHLX', 'JNX5'('JNK'), 'JX5'('JK')



# Четыре функции преобразования
def shex4 (a):
    s = str(stri[(a%65536)//4096]) + str(stri[(a%4096)//256]) + str(stri[((a%256)//16)]) + str(stri[a%16])
    return (s) #convert int to hex, len = 4-bit const
def shex2 (a):
    s = stri[a//16] + stri[a%16]
    return (s) #convert int to hex, len = 2-bit const
def sthex4 (s):
    answ = 0
    for i in range (16):
        if ord(s[0]) == ord(stri[i]):
            answ += (16**3)*(i)
        if ord(s[1]) == ord(stri[i]):
            answ += (16**2)*(i)
        if ord(s[2]) == ord(stri[i]):
            answ += 16*(i)
        if ord(s[3]) == ord(stri[i]):
            answ += (i)
    return (answ)
def sthex2 (s):
    answ = 0
    for i in range (16):
        if ord(s[0]) == ord(stri[i]):
            answ += 16*(i)
        if ord(s[1]) == ord(stri[i]):
            answ += (i)
    return (answ) #convert str(hex) to int, 2-bit
def regtohex (s):
    k = 0
    for i in range (8):
        if ord(s) == ord(w[i]):
            k = i
    return (k)
# если случилась ошибка операнда, уведомляет об этом
def operand_error():
    print('! Operand error !')
    raise Exception("Podstava")
    #file_list_out.write('! Operand error !')
    #file_out.close()
    while True:
        pass
# преобразует букву 8-р регистра в его код
def reg_to_code(s):
    if s == 'b':
        out = 0b000
    elif s == 'c':
        out = 0b001
    elif s == 'd':
        out = 0b010
    elif s == 'e':
        out = 0b011
    elif s == 'h':
        out = 0b100
    elif s == 'l':
        out = 0b101
    elif s == 'm':
        out = 0b110
    elif s == 'a':
        out = 0b111
    else:
        operand_error()
    return out

















# (1)
# Тип MOV -- 2 операнда, 8-р регистры
# - MOV
# sr - строка ассемблерного кода, поделенная по словам
def type_mov(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    #формирование опкода
    opcode += reg_to_code(sr[1][0].lower())*8
    opcode += reg_to_code(sr[1][-1].lower())
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] + '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '    '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    # увеличение счетчика pc
    addr_pc += 1

# (2)
# Тип ADD -- 1 операнд, 8-р регистр в 0-1-2 разрядах
# - ADD
# - ADC
# - SUB
# - SBB
# - ANA
# - ORA
# - XRA
# - CMP
def type_add(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    #формирование опкода
    opcode += reg_to_code(sr[1][0].lower())
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] + '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 1

# (3)
# Тип MVI -- 1 операнд, 8-р регистр в 3-4-5 разрядах плюс байт данных
#- MVI
def type_mvi(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    # var_usage - булевская переменная, тру, если байты данных после машинной инструкции - это переменная
    var_usage = True
    #if len(sr[1]) == 3:
    if sr[1][-1].lower() == 'h' or sr[1][-3] == '$':
        var_usage = False
    #формирование опкода
    opcode += reg_to_code(sr[1][0].lower())*8
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] + '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
            
    if var_usage:
        var_peru = var_list[sr[1][2:]]
        if var_peru == None:
            operand_error()
        sr_opcode = shex2(var_peru)
    else:
        if sr[1][-3] == '$':
            sr_opcode = sr[1][-2] + sr[1][-1]
        else:
            sr_opcode = sr[1][-3] + sr[1][-2]
    machine_output += sr_opcode
    sr_list_out += shex4(addr_pc+1) + ' ' + sr_opcode
    sr_list_out += '\n'
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 2

# (4)
# Тип ADI -- без операнда плюс байт данных
# - ADI
# - ACI
# - SUI
# - SBI
# - ANI
# - ORI
# - XRI
# - CPI
# - IN
# - OUT
def type_adi(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    # var_usage - булевская переменная, тру, если байты данных после машинной инструкции - это переменная
    var_usage = True
    #if len(sr[1]) == 3:
    if sr[1][-1].lower() == 'h' or sr[1][-3] == '$':
        var_usage = False
    #формирование опкода (нет, тк без операнда)
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] + '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
            
    if var_usage:
        var_peru = var_list[sr[1]]
        if var_peru == None:
            operand_error()
        sr_opcode = shex2(var_peru)
    else:
        if sr[1][-3] == '$':
            sr_opcode = sr[1][-2] + sr[1][-1]
        else:
            sr_opcode = sr[1][-3] + sr[1][-2]
    machine_output += sr_opcode
    sr_list_out += shex4(addr_pc+1) + ' ' + sr_opcode
    sr_list_out += '\n'
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 2

# (5)
# Тип INR -- 1 операнд, 8-р регистр в 3-4-5 разрядах
# - INR
# - DCR
def type_inr(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    if len(sr[1]) > 1:
        operand_error()
    #формирование опкода
    opcode += reg_to_code(sr[1].lower())*8
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] + '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 1

# (6)
# Тип RAL --  без операнда
# - RLC
# - RRC
# - RAL
# - RAR
# - RET
# - RC-RPO
# - XTHL
# - XCHG
# - SPHL
# - PCHL
# - CMA
# - STC
# - CMC
# - DAA
# - EI
# - DI
# - NOP
# - RIM
# - SIM
# - HLT
def type_ral(sr, opcode):
    #проверка наличия операнда
    #формирование опкода
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0]
    if sr[0] == 'ldax' or sr[0] == 'stax':
        sr_list_out += '  ' + sr[1]
        if len(sr) > 2 and sr[2][0] == ';':
            sr_list_out += '      '
            for i in range(2,len(sr)):
                sr_list_out += ' ' + sr[i]
    else:
        if len(sr) > 1 and sr[1][0] == ';':
            sr_list_out += '      '
            for i in range(1,len(sr)):
                sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 1

# (7)
# Тип JMP -- без операнда плюс 2 байта данных
# - JMP
# - JC-JPO
# - CALL
# - CC-CPO
# - LDA
# - STA
# - LHLD
# - SHLD
def type_jmp(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    # var_usage - булевская переменная, тру, если байты данных после машинной инструкции - это переменная
    var_usage = True
    if len(sr[1]) == 5:
        if sr[1][-1].lower() == 'h' or sr[1][-5] == '$':
            var_usage = False
    #формирование опкода
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] #+ '  ' + sr[1]
    if len(sr[0]) == 2:
        sr_list_out += '    ' + sr[1]
    elif len(sr[0]) == 3:
        sr_list_out += '   ' + sr[1]
    else:
        sr_list_out += '  ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
            
    if var_usage:
        var_peru = var_list.get(sr[1],0)
        if var_peru == None:
            operand_error()
        var_sr = shex4(var_peru)
        sr_opcode1 = var_sr[2] + var_sr[3]
        sr_opcode2 = var_sr[0] + var_sr[1]
    else:
        if sr[1][-5] == '$':
            sr_opcode1 = sr[1][-2] + sr[1][-1]
            sr_opcode2 = sr[1][-4] + sr[1][-3]
        else:
            sr_opcode1 = sr[1][-3] + sr[1][-2]
            sr_opcode2 = sr[1][-5] + sr[1][-4]
    machine_output += sr_opcode1
    machine_output += sr_opcode2
    
    sr_list_out += shex4(addr_pc+1) + ' ' + sr_opcode1
    sr_list_out += '\n'
    sr_list_out += shex4(addr_pc+2) + ' ' + sr_opcode2
    sr_list_out += '\n'
    
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 3
    
# (8)
# Тип DAD -- регистровая пара
# - DAD
# - PUSH
# - POP
# - INX
# - DCX
def type_dad(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    #формирование опкода (опкод с учетом операнда формируется на первой стадии дешифрации)
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] #+ ' ' + sr[1]
    if len(sr[0]) == 4:
        sr_list_out += '  ' + sr[1]
    else:
        sr_list_out += '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'

    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 1
    
# (9)
# Тип LXI -- регистровая пара плюс 2 байта данных
# - LXI
# - LDAX
# - STAX
def type_lxi(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    # var_usage - булевская переменная, тру, если байты данных после машинной инструкции - это переменная
    var_usage = True
    #if len(sr[1]) == 5:
    if sr[1][-1].lower() == 'h' or sr[1][-5] == '$':
        var_usage = False
    #формирование опкода (опкод с учетом операнда формируется на первой стадии дешифрации)
    #формирование строк вывода
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] + '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
    
    global var_list
    if var_usage:
        if sr[1][0] == 's':
            var_peru = var_list.get(sr[1][3:],0)
        else:
            var_peru = var_list.get(sr[1][2:],0)
        if var_peru == None:
            operand_error()
        var_sr = shex4(var_peru)
        sr_opcode1 = var_sr[2] + var_sr[3]
        sr_opcode2 = var_sr[0] + var_sr[1]
    else:
        if sr[1][-5] == '$':
            sr_opcode1 = sr[1][-2] + sr[1][-1]
            sr_opcode2 = sr[1][-4] + sr[1][-3]
        else:
            sr_opcode1 = sr[1][-3] + sr[1][-2]
            sr_opcode2 = sr[1][-5] + sr[1][-4]
    machine_output += sr_opcode1
    machine_output += sr_opcode2
    
    sr_list_out += shex4(addr_pc+1) + ' ' + sr_opcode1
    sr_list_out += '\n'
    sr_list_out += shex4(addr_pc+2) + ' ' + sr_opcode2
    sr_list_out += '\n'

    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 3
    
# (10)
# Тип RST -- 1 операнд, адрес прерывания в 3-4-5 разрядах
#- RST
def type_rst(sr, opcode):
    #проверка наличия операнда
    if len(sr) < 2:
        operand_error()
    if sr[1][-1].lower() != 'h' and sr[1][-3] != '$':
        operand_error()
    
    #формирование опкода
    #формирование строк вывода
    
    if sr[1][-3] == '$':
        sr_addr_rst = sr[1][-2] + sr[1][-1]
    else:
        sr_addr_rst = sr[1][-3] + sr[1][-2]
    if sthex2(sr_addr_rst) > 7:
        operand_error()
    opcode += sthex2(sr_addr_rst)*8
    sr_opcode = shex2(opcode)
    global machine_output
    machine_output += sr_opcode
    global addr_pc
    sr_list_out = shex4(addr_pc) + ' ' + sr_opcode + '    ' + sr[0] + '   ' + sr[1]
    if len(sr) > 2 and sr[2][0] == ';':
        sr_list_out += '      '
        for i in range(2,len(sr)):
            sr_list_out += ' ' + sr[i]
    sr_list_out += '\n'
    
    file_list_out.write(sr_list_out)
    #print(sr_list_out[:-1])
    addr_pc += 1


def translator(file_name):
    # main cycle
    comm_list = []
    f = open(file_name, "r")
    for line in f:
        comm_list.append(str(line))
    f.close()
    
    for index in range(len(comm_list)):
        string = comm_list[index].split()
    
        if len(string) == 0:
            file_list_out.write('\n')
            
        elif string[0].lower() == '.include':
            f_name = string[1]
            translator(f_name)
            
    # (1) type 'MOV'
        elif string[0].lower() == 'mov':
            opcode = 0x40
            type_mov(string, opcode)
        
    # (2) type 'MVI'
        elif string[0].lower() == 'mvi':
            opcode = 0x06
            type_mvi(string, opcode)
        
    # (3) type 'LXI'
        elif string[0].lower() == 'lxi':
            opcode = 0x01
            pair = string[1][0].lower()
            if pair == 'd':
                opcode += 0x10
            if pair == 'h':
                opcode += 0x20
            if pair == 's':
                opcode += 0x30
            type_lxi(string, opcode)
        
    # (4) type 'LDAX'
        elif string[0].lower() == 'ldax':
            opcode = 0x0A
            if string[1].lower() == 'd':
                opcode += 0x10
            type_ral(string, opcode)
        
    # (5) type 'STAX'
        elif string[0].lower() == 'stax':
            opcode = 0x02
            if string[1].lower() == 'd':
                opcode += 0x10
            type_ral(string, opcode)
        
        
    # (6) type 'LHLD'
        elif string[0].lower() == 'lhld':
            opcode = 0x2A
            type_jmp(string, opcode)
        
    # (7) type 'SHLD'
        elif string[0].lower() == 'shld':
            opcode = 0x22
            type_jmp(string, opcode)
        
    # (8) type 'XCHG'
        elif string[0].lower() == 'xchg':
            opcode = 0xEB
            type_ral(string, opcode)
        
    # (9) type 'PUSH'
        elif string[0].lower() == 'push':
            opcode = 0xC5
            pair = string[1].lower()
            if pair == 'd':
                opcode += 0x10
            if pair == 'h':
                opcode += 0x20
            if pair == 'psw':
                opcode += 0x30
            type_dad(string, opcode)
        
        
    # (10) type 'POP'
        elif string[0].lower() == 'pop':
            opcode = 0xC1
            pair = string[1].lower()
            if pair == 'd':
                opcode += 0x10
            if pair == 'h':
                opcode += 0x20
            if pair == 'psw':
                opcode += 0x30
            type_dad(string, opcode)
        
    # (11) type 'SPHL'
        elif string[0].lower() == 'sphl':
            opcode = 0xF9 # или FB ????????
            type_ral(string, opcode)
        
    # (12) type 'XTHL'
        elif string[0].lower() == 'xthl':
            opcode = 0xE3
            type_ral(string, opcode)
        
    # (13) type 'PCHL'
        elif string[0].lower() == 'pchl':
            opcode = 0xE9
            type_ral(string, opcode)
        
    # (14) type 'JMP'
        elif string[0].lower() == 'jmp':
            opcode = 0xC3
            type_jmp(string, opcode)
        
    # (15) type 'JC'
        elif string[0].lower() == 'jc':
            opcode = 0xDA
            type_jmp(string, opcode)
        
    # (16) type 'JNC'
        elif string[0].lower() == 'jnc':
            opcode = 0xD2
            type_jmp(string, opcode)
        
    # (17) type 'JZ'
        elif string[0].lower() == 'jz':
            opcode = 0xCA
            type_jmp(string, opcode)
        
    # (18) type 'JNZ'
        elif string[0].lower() == 'jnz':
            opcode = 0xC2
            type_jmp(string, opcode)
        
    # (19) type 'JP'
        elif string[0].lower() == 'jp':
            opcode = 0xF2
            type_jmp(string, opcode)
        
    # (20) type 'JM'
        elif string[0].lower() == 'jm':
            opcode = 0xFA
            type_jmp(string, opcode)
        
    # (21) type 'JPE'
        elif string[0].lower() == 'jpe':
            opcode = 0xEA
            type_jmp(string, opcode)
        
    # (22) type 'JPO'
        elif string[0].lower() == 'jpo':
            opcode = 0xE2
            type_jmp(string, opcode)
        
    # (23) type 'CALL'
        elif string[0].lower() == 'call':
            opcode = 0xCD
            type_jmp(string, opcode)
        
    # (24) type 'CC'
        elif string[0].lower() == 'cc':
            opcode = 0xDC
            type_jmp(string, opcode)
        
    # (25) type 'CNC'
        elif string[0].lower() == 'cnc':
            opcode = 0xD4
            type_jmp(string, opcode)
        
    # (26) type 'CZ'
        elif string[0].lower() == 'cz':
            opcode = 0xCC
            type_jmp(string, opcode)
        
    # (27) type 'CNZ'
        elif string[0].lower() == 'cnz':
            opcode = 0xC4
            type_jmp(string, opcode)
        
    # (28) type 'CP'
        elif string[0].lower() == 'cp':
            opcode = 0xF4
            type_jmp(string, opcode)
        
    # (29) type 'CM'
        elif string[0].lower() == 'cm':
            opcode = 0xFC
            type_jmp(string, opcode)
        
    # (30) type 'CPE'
        elif string[0].lower() == 'cpe':
            opcode = 0xEC
            type_jmp(string, opcode)
        
    # (31) type 'CPO'
        elif string[0].lower() == 'cpo':
            opcode = 0xE4
            type_jmp(string, opcode)
        
    # (32) type 'RET'
        elif string[0].lower() == 'ret':
            opcode = 0xC9
            type_ral(string, opcode)
        
    # (33) type 'RC'
        elif string[0].lower() == 'rc':
            opcode = 0xD8
            type_ral(string, opcode)
        
    # (34) type 'RNC'
        elif string[0].lower() == 'rnc':
            opcode = 0xD0
            type_ral(string, opcode)
        
    # (35) type 'RZ'
        elif string[0].lower() == 'rz':
            opcode = 0xC8
            type_ral(string, opcode)
        
    # (36) type 'RNZ'
        elif string[0].lower() == 'rnz':
            opcode = 0xC0
            type_ral(string, opcode)
        
    # (37) type 'RP'
        elif string[0].lower() == 'rp':
            opcode = 0xF0
            type_ral(string, opcode)
        
    # (38) type 'RM'
        elif string[0].lower() == 'rm':
            opcode = 0xF8
            type_ral(string, opcode)
        
    # (39) type 'RPE'
        elif string[0].lower() == 'rpe':
            opcode = 0xE8
            type_ral(string, opcode)
        
    # (40) type 'RPO'
        elif string[0].lower() == 'rpo':
            opcode = 0xE0
            type_ral(string, opcode)
        
    # (41) type 'RST'
        elif string[0].lower() == 'rst':
            opcode = 0xC7
            type_rst(string, opcode)
        
    # (42) type 'IN'
        elif string[0].lower() == 'in':
            opcode = 0xDB
            type_adi(string, opcode)
        
    # (43) type 'OUT'
        elif string[0].lower() == 'out':
            opcode = 0xD3
            type_adi(string, opcode)
        
    # (44) type 'INR'
        elif string[0].lower() == 'inr':
            opcode = 0x04
            type_inr(string, opcode)
        
    # (45) type 'DCR'
        elif string[0].lower() == 'dcr':
            opcode = 0x05
            type_inr(string, opcode)
        
    # (46) type 'INX'
        elif string[0].lower() == 'inx':
            opcode = 0x03
            pair = string[1].lower()
            if pair == 'd':
                opcode += 0x10
            if pair == 'h':
                opcode += 0x20
            if pair == 'sp':
                opcode += 0x30
            type_dad(string, opcode)
        
    # (47) type 'DCX'
        elif string[0].lower() == 'dcx':
            opcode = 0x0B
            pair = string[1].lower()
            if pair == 'd':
                opcode += 0x10
            if pair == 'h':
                opcode += 0x20
            if pair == 'sp':
                opcode += 0x30
            type_dad(string, opcode)
        
    # (48) type 'ADD'
        elif string[0].lower() == 'add':
            opcode = 0x80
            type_add(string, opcode)
        
    # (49) type 'ADC'
        elif string[0].lower() == 'adc':
           opcode = 0x88
           type_add(string, opcode) 
        
    # (50) type 'ADI'
        elif string[0].lower() == 'adi':
            opcode = 0xC6
            type_adi(string, opcode)
        
    # (51) type 'ACI'
        elif string[0].lower() == 'aci':
            opcode = 0xCE
            type_adi(string, opcode)
        
    # (52) type 'DAD'
        elif string[0].lower() == 'dad':
            opcode = 0x09
            pair = string[1].lower()
            if pair == 'd':
                opcode += 0x10
            if pair == 'h':
                opcode += 0x20
            if pair == 'sp':
                opcode += 0x30
            type_dad(string, opcode)
        
    # (53) type 'SUB'
        elif string[0].lower() == 'sub':
            opcode = 0x90
            type_add(string, opcode)
        
    # (54) type 'SBB'
        elif string[0].lower() == 'sbb':
            opcode = 0x98
            type_add(string, opcode)
        
    # (55) type 'SUI'
        elif string[0].lower() == 'sui':
            opcode = 0xD6
            type_adi(string, opcode)
        
    # (56) type 'SBI'
        elif string[0].lower() == 'sbi':
            opcode = 0xDE
            type_adi(string, opcode)
        
    # (57) type 'ANA'
        elif string[0].lower() == 'ana':
            opcode = 0xA0
            type_add(string, opcode)
        
    # (58) type 'ORA'
        elif string[0].lower() == 'ora':
            opcode = 0xB0
            type_add(string, opcode)
          
    # (59) type 'XRA'
        elif string[0].lower() == 'xra':
            opcode = 0xA8
            type_add(string, opcode)
        
    # (60) type 'CMP'
        elif string[0].lower() == 'cmp':
            opcode = 0xB8
            type_add(string, opcode)
        
    # (61) type 'ANI'
        elif string[0].lower() == 'ani':
            opcode = 0xE6
            type_adi(string, opcode)
         
    # (62) type 'ORI'
        elif string[0].lower() == 'ori':
            opcode = 0xF6
            type_adi(string, opcode)
        
    # (63) type 'XRI'
        elif string[0].lower() == 'xri':
            opcode = 0xEE
            type_adi(string, opcode)
        
    # (64) type 'CPI'
        elif string[0].lower() == 'cpi':
            opcode = 0xFE
            type_adi(string, opcode)
        
    # (65) type 'RLC'
        elif string[0].lower() == 'rlc':
            opcode = 0x07
            type_ral(string, opcode)
        
    # (66) type 'RRC'
        elif string[0].lower() == 'rrc':
           opcode = 0x0F
           type_ral(string, opcode) 
        
    # (67) type 'RAL'
        elif string[0].lower() == 'ral':
            opcode = 0x17
            type_ral(string, opcode)
        
    # (68) type 'RAR'
        elif string[0].lower() == 'rar':
            opcode = 0x1F
            type_ral(string, opcode)
        
    # (69) type 'CMA'
        elif string[0].lower() == 'cma':
            opcode = 0x2F
            type_ral(string, opcode)
        
    # (70) type 'STC'
        elif string[0].lower() == 'stc':
            opcode = 0x37
            type_ral(string, opcode)
        
    # (71) type 'CMC'
        elif string[0].lower() == 'cmc':
            opcode = 0x3F
            type_ral(string, opcode)
        
    # (72) type 'DAA'
        elif string[0].lower() == 'daa':
            opcode = 0x27
            type_ral(string, opcode)
        
    # (73) type 'EI'
        elif string[0].lower() == 'ei':
            opcode = 0xFB
            type_ral(string, opcode)
        
    # (74) type 'DI'
        elif string[0].lower() == 'di':
            opcode = 0xF3
            type_ral(string, opcode)
        
    # (75) type 'NOP'
        elif string[0].lower() == 'nop':
            opcode = 0x00
            type_ral(string, opcode)
        
    # (76) type 'HLT'
        elif string[0].lower() == 'hlt':
            opcode = 0x76
            type_ral(string, opcode)
        
    # (77) type 'RIM'
        elif string[0].lower() == 'rim':
            opcode = 0x20
            type_ral(string, opcode)
        
    # (78) type 'SIM'
        elif string[0].lower() == 'sim':
            opcode = 0x30
            type_ral(string, opcode)
            
    # (79) type 'LDA'
        elif string[0].lower() == 'lda':
            opcode = 0x3A
            type_jmp(string, opcode)
            
    # (80) type 'STA'
        elif string[0].lower() == 'sta':
            opcode = 0x32
            type_jmp(string, opcode)
            
    # Недокументированные инструкции:
    # (81) type 'DSUB'
        elif string[0].lower() == 'dsub':
            opcode = 0x08
            type_ral(string, opcode)
            
    # (82) type 'ARHL'
        elif string[0].lower() == 'arhl':
            opcode = 0x10
            type_ral(string, opcode)
            
    # (83) type 'RDEL'
        elif string[0].lower() == 'rdel':
            opcode = 0x18
            type_ral(string, opcode)
            
    # (84) type 'LDHI'
        elif string[0].lower() == 'ldhi':
            opcode = 0x28
            type_adi(string, opcode)
            
    # (85) type 'LDSI'
        elif string[0].lower() == 'ldsi':
            opcode = 0x38
            type_adi(string, opcode)
            
    # (86) type 'RSTV'
        elif string[0].lower() == 'rstv':
            opcode = 0xCB
            type_ral(string, opcode)
            
    # (87) type 'SHLX'
        elif string[0].lower() == 'shlx':
            opcode = 0xD9
            type_ral(string, opcode)
            
    # (88) type 'LHLX'
        elif string[0].lower() == 'lhlx':
            opcode = 0xED
            type_ral(string, opcode)
            
    # (89) type 'JNX5'
        elif string[0].lower() == 'jnx5':
            opcode = 0xDD
            type_jmp(string, opcode)
        elif string[0].lower() == 'jnk':
            opcode = 0xDD
            type_jmp(string, opcode)
            
    # (90) type 'JX5'
        elif string[0].lower() == 'jx5':
            opcode = 0xFD
            type_jmp(string, opcode)
        elif string[0].lower() == 'jk':
            opcode = 0xFD
            type_jmp(string, opcode)
            
    
    
            
    # Если '.include'
    # Если '.def'
        elif string[0].lower() == '.def':
            #print(string)
            if string[2] == '=':
                value = string[3]
                if len(value) == 5:
                    if value[0] == '$':
                        val = sthex4(value[1:])
                    elif value[-1].lower() == 'h':
                        val = sthex4(value[:-1])
                    else:
                        val = var_list[value]
                elif len(value) == 3:
                    if value[0] == '$':
                        val = sthex2(value[1:])
                    elif value[-1].lower() == 'h':
                        val = sthex2(value[:-1])
                    else:
                        val = var_list[value]
                else:
                    val = var_list[value]
                var_list[string[1]] = val
                sr_list_out = '.def ' + string[1] + ' = ' + string[3]
                if len(string) > 4 and string[4][0] == ';':
                    sr_list_out += '      '
                    for i in range(4,len(string)):
                        sr_list_out += ' ' + string[i]
                sr_list_out += '\n'
                file_list_out.write(sr_list_out)
                #print(sr_list_out[:-1])
            else:
                operand_error()
            
    # Если '.db'
        elif string[0].lower() == '.db':
            if string[1][0] == '$':
                sr_opcode = string[1][1]+string[1][2]
            elif string[1][-1].lower() == 'h':
                sr_opcode = string[1][0]+string[1][1]
            else:
                sr_opcode = shex2(var_list.get(string[1],0))
            global machine_output
            machine_output += sr_opcode.upper()
            global addr_pc
            sr_list_out = string[0] + ' ' + string[1]
            if len(string) > 2:
                sr_list_out += '      '
                for i in range(2,len(string)):
                    sr_list_out += ' ' + string[i]
            sr_list_out += '\n' + shex4(addr_pc) + ' ' + sr_opcode + '\n'
            file_list_out.write(sr_list_out)
            addr_pc += 1
            
    # Если '.dw'
        elif string[0].lower() == '.dw':
            if string[1][0] == '$':
                sr_opcode1 = string[1][3]+string[1][4]
                sr_opcode2 = string[1][1]+string[1][2]
            elif string[1][-1].lower() == 'h':
                sr_opcode1 = string[1][2]+string[1][3]
                sr_opcode2 = string[1][0]+string[1][1]
            else:
                val = shex4(var_list.get(string[1],0))
                sr_opcode1 = val[2]+val[3]
                sr_opcode2 = val[0]+val[1]
            #global machine_output
            machine_output += sr_opcode1.upper() + sr_opcode2.upper()
            #global addr_pc
            sr_list_out = string[0] + ' ' + string[1]
            if len(string) > 2:
                sr_list_out += '      '
                for i in range(2,len(string)):
                    sr_list_out += ' ' + string[i]
            sr_list_out += '\n'
            sr_list_out += shex4(addr_pc) + ' ' + sr_opcode1
            sr_list_out += '\n'
            sr_list_out += shex4(addr_pc+1) + ' ' + sr_opcode2
            sr_list_out += '\n'
            file_list_out.write(sr_list_out)
            addr_pc += 2
            
    # Если '.ds'
        elif string[0].lower() == '.ds':
            #print(string)
            if not((string[1][0] == '"')and(string[1][-1] == '"') or (string[1][0] == "'")and(string[1][-1] == "'")):
                operand_error()
            sr_opcode = ''
            #global addr_pc
            sr_list_out = string[0] + ' ' + string[1]
            if len(string) > 2:
                sr_list_out += '      '
                for i in range(2,len(string)):
                    sr_list_out += ' ' + string[i]
            sr_list_out += '\n'
            
            for i in range(1,len(string[1])-1):
                sr_opcode += shex2(ord(string[1][i]))
                sr_list_out += shex4(addr_pc) + ' ' + shex2(ord(string[1][i])) + " '" + string[1][i] + "'\n"
                addr_pc += 1   
            #global machine_output
            machine_output += sr_opcode
            file_list_out.write(sr_list_out)
            
    # Если '.org'
        elif string[0].lower() == '.org':
            if string[1][0] == '$':
                sr_opcode1 = string[1][3]+string[1][4]
                sr_opcode2 = string[1][1]+string[1][2]
            elif string[1][-1].lower() == 'h':
                sr_opcode1 = string[1][2]+string[1][3]
                sr_opcode2 = string[1][0]+string[1][1]
            else:
                val = shex4(var_list.get(string[1],0))
                sr_opcode1 = val[2]+val[3]
                sr_opcode2 = val[0]+val[1]
            val = sthex4(sr_opcode2 + sr_opcode1)
            if addr_pc < val:
                for i in range(addr_pc, val):
                    machine_output += 'FF'
                addr_pc = val
            sr_list_out = string[0] + '   ' + string[1]
            if len(string) > 2:
                sr_list_out += '      '
                for i in range(2,len(string)):
                    sr_list_out += ' ' + string[i]
            sr_list_out += '\n'
            file_list_out.write(sr_list_out)
            
    # Если ';'
        elif string[0][0] == ';':
            sr_list_out = string[0]
            if len(string) > 1:
                #sr_list_out += '      '
                for i in range(1,len(string)):
                    sr_list_out += ' ' + string[i]
            sr_list_out += '\n'
            file_list_out.write(sr_list_out)
            #print(sr_list_out[:-1])
    # Если ':'
        elif string[0][-1] == ':':
            var_list[string[0][:-1]] = addr_pc
            sr_list_out = string[0] + ' (' + shex4(addr_pc) + ')'
            if len(string) > 1 and string[1][0] == ';':
                sr_list_out += '      '
                for i in range(1,len(string)):
                    sr_list_out += ' ' + string[i]
            sr_list_out += '\n'
            file_list_out.write(sr_list_out)
            #print(sr_list_out[:-1])
    
#    file_list_out.close()
    
    
global stri
stri = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']
# Ввод адреса начала
print('Введите адрес начала:')
sr_in = input()
if sr_in[0] == '$':
    addr_alku = sthex4(sr_in[1:])
elif sr_in[-1].lower() == 'h':
    addr_alku = sthex4(sr_in[:-1])
else:
    print('Error')
    while True:
        pass
# Список переменных
# global var_list
var_list = dict()
# Главный выход машинного кода
# global machine_output
machine_output = ''
# Разбор кода транслятором -- файл file_out

# global comm_list
# comm_list = []
# f = open('/home/victor/Desktop/Enter1.0', "r")
# for line in f:
#     comm_list.append(str(line))
# f.close()

print('Первый прогон, получение значений меток и переменных...')
file_list_out = open('/home/victor/Desktop/OutEnter1.0', "w")
addr_pc = addr_alku
translator('/home/victor/Desktop/Enter1.0')
file_list_out.close()
machine_output = ''
print('---------------------------------------')
print('Генерация машинного кода...')
file_list_out = open('/home/victor/Desktop/OutEnter1.0', "w")
addr_pc = addr_alku
translator('/home/victor/Desktop/Enter1.0')
file_list_out.close()

print('---------------------------------------')
print('Сохранение...\n')
f_machine_output = open('/home/victor/Desktop/MachineOutput', "w")
f_machine_output.write(machine_output)
f_machine_output.close()

print('Адрес конца: ' + shex4(addr_pc))
print(var_list)
