# Недо-бейсиковский кросс-транслятор
# 
# 
# 
# 
# 
# 
# 

def shex4 (a):
    s = str(stri[(a%65536)//4096]) + str(stri[(a%4096)//256]) + str(stri[((a%256)//16)]) + str(stri[a%16])
    return (s) #convert int to hex, len = 4-bit const

def shex2 (a):
    s = stri[a//16] + stri[a%16]
    return (s) #convert int to hex, len = 2-bit const

def gapskip(sr): #пропуск всех пробелов в строке
    s = ''
    for i in range(len(sr)):
        if (sr[i]!=' ')and(sr[i]!='\n'):
            s += sr[i]
    return s

def str_to_int(s):
    coef = 1
    if s[0] == '-':
        s = s[1:]
        coef = -1
    if s[0] != '0':
        return int(s)*coef
    if len(s) > 2:
        if s[1].lower() == 'x':
            return int(s[2:],16)*coef
        if s[1].lower() == 'b':
            return int(s[2:],2)*coef
    return int(s,8)*coef

def ValueIsNumber(s):
    if ord(s[0])<=0x39:
        return True
    else:
        return False

def ValueToStr4(s):
    if ValueIsNumber(s):
        return '$' + shex4(str_to_int(s))
    else:
        return s

def ValueToStr2(s):
    if ValueIsNumber(s):
        return '$' + shex2(str_to_int(s))
    else:
        return s

def SymOfVar(s):
    s = s.upper()
    if 0x30<=ord(s)<=0x39 or 0x41<=ord(s)<=0x5A or s=='_':
        return True
    else:
        return False
    
###############################################################################
    
#Оператор присвоения
def type_set(val1, val2, operation, id_op):
    srout = ''
    #если первое значение - число, то ничего не делаем
    if ValueIsNumber(val1):
        return srout
    #первое значение - переменная.
    VarType = varlist.get(val1)[0]
    if VarType == 'byte' or VarType == 'shortint':
            if ValueIsNumber(val2):
                srout += '    mvi     a,' + ValueToStr2(val2) + '\n'
            else:
                srout += '    lda     ' + ValueToStr2(val2) + '\n'
            if operation == '!':
                srout += '    cma\n'
            srout += '    sta     ' + ValueToStr2(val1) + '\n'
    elif VarType == 'word' or VarType == 'int':
        if ValueIsNumber(val2):
            if operation == '0':
                srout += '    lxi     h,' + ValueToStr4(val2) + '\n'
            else:
                srout += '    lxi     h,$' + shex4(65535-str_to_int(val2)) + '\n'
            srout += '    shld    ' + ValueToStr4(val1) + '\n'
        elif varlist.get(val2)[0] == 'byte':
            if operation == '0':
                srout += '    lhld    ' + ValueToStr4(val2) + '\n'
                srout += '    mvi     h,$00\n'
                srout += '    shld    ' + ValueToStr4(val1) + '\n'
            else: #=='!'
                srout += '    lda     ' + ValueToStr4(val2) + '\n'
                srout += '    cma\n'
                srout += '    mvi     h,$FF\n'
                srout += '    mov     l,a\n'
                srout += '    shld    ' + ValueToStr4(val1) + '\n'
        elif varlist.get(val2)[0] == 'shortint':
            srout += '    lda     ' + ValueToStr4(val2) + '\n'
            if operation == '!':
                srout += '    cma\n'
            srout += '    mov     l,a\n'
            srout += '    mvi     h,$00\n'
            srout += '    ora     a\n'
            srout += '    jp      Metka_' + str(id_op) + '\n'
            srout += '    mvi     h,$FF\n'
            srout += 'Metka_' + str(id_op) + ':\n'
            srout += '    shld    ' + val1 + '\n'
        elif varlist.get(val2)[0] == 'word' or varlist.get(val2)[0] == 'int':
            srout += '    lhld    ' + ValueToStr4(val2) + '\n'
            if operation == '!':
                srout += '    mov     a,h\n'
                srout += '    cma\n'
                srout += '    mov     h,a\n'
                srout += '    mov     a,l\n'
                srout += '    cma\n'
                srout += '    mov     l,a\n'
            srout += '    shld    ' + val1 + '\n'
    return srout
    
#Оператор объявления переменной
def type_var(name, vartype, var_address, id_op, value=''):
    #Добавляем переменную в список переменных
    varlist[name] = [vartype, var_address]
    #
    srout = ''
    srout += '.def ' + name + ' = $' + shex4(var_address) + '\n'
    if len(value) != 0:
        if ValueIsNumber(value): #переменной присваивается числовое значение
            if vartype == 'byte' or vartype == 'shortint':
                srout += '    mvi     a,' + ValueToStr2(value) + '\n'
                srout += '    sta     ' + name + '\n'
            else:
                srout += '    lxi     h,' + ValueToStr4(value) + '\n'
                srout += '    shld    ' + name + '\n'
        else: #переменной присваивается значение переменной
            if vartype == 'byte' or vartype == 'shortint':
                srout += '    lda     ' + value + '\n'
                srout += '    sta     ' + name + '\n'
            else:
                TypeValue = varlist.get(value)[0]
                if TypeValue == 'byte':
                    srout += '    lhld    ' + value + '\n'
                    srout += '    mvi     h,$00\n'
                    srout += '    shld    ' + name + '\n'
                elif TypeValue == 'shortint':
                    srout += '    lda     ' + value + '\n'
                    srout += '    mov     l,a\n'
                    srout += '    mvi     h,$00\n'
                    srout += '    ora     a\n'
                    srout += '    jp      Metka_' + str(id_op) + '\n'
                    srout += '    mvi     h,$FF\n'
                    srout += 'Metka_' + str(id_op) + ':\n'
                    srout += '    shld    ' + name + '\n'
                else: #word, int
                    srout += '    lhld    ' + value + '\n'
                    srout += '    shld    ' + name + '\n'
    return srout


def type_math(val_out, val1, val2, operation, id_op):
    srout = ''
    #если первое значение - число, то ничего не делаем
    if ValueIsNumber(val1):
        return srout
    #первое значение - переменная.
    
    #Загрузка Val1 и Val2
    srout += load_val2(val2, id_op)
    srout += load_val1(val1, id_op)
    
    #TypeVal1 = varlist.get(val1)[0]
    #TypeVal2 = varlist.get(val2)[0]
    
    if operation == '+':
        srout += '    dad     d\n'
    elif operation == '-':
        srout += '    mov     a,l\n'
        srout += '    sub     e\n'
        srout += '    mov     l,a\n'
        srout += '    mov     a,h\n'
        srout += '    sbb     d\n'
        srout += '    mov     h,a\n'
    elif operation == '&':
        srout += '    mov     a,l\n'
        srout += '    ana     e\n'
        srout += '    mov     l,a\n'
        srout += '    mov     a,h\n'
        srout += '    ana     d\n'
        srout += '    mov     h,a\n'
    elif operation == '|':
        srout += '    mov     a,l\n'
        srout += '    ora     e\n'
        srout += '    mov     l,a\n'
        srout += '    mov     a,h\n'
        srout += '    ora     d\n'
        srout += '    mov     h,a\n'
    elif operation == '^':
        srout += '    mov     a,l\n'
        srout += '    xra     e\n'
        srout += '    mov     l,a\n'
        srout += '    mov     a,h\n'
        srout += '    xra     d\n'
        srout += '    mov     h,a\n'
    elif operation == '*':
        srout += '    call    MUL16\n'
    elif operation == '//':
        srout += '    call    UDIV16\n'
    elif operation == '%':
        srout += '    call    UDIV16\n'
        srout += '    xchg\n'
    
    Type_val_out = varlist.get(val_out)[0]
    if Type_val_out == 'byte' or Type_val_out == 'shortint':
        srout += '    mov     a,l\n'
        srout += '    sta     ' + val_out + '\n'
    else:
        srout += '    shld    ' + val_out + '\n'
    return srout
    
def load_val1(val1, id_op):
    #загрузка в HL
    srout = ''
    if ValueIsNumber(val1):
            srout += '    lxi     h,' + ValueToStr4(val1) + '\n'
    else:
        TypeVal1 = varlist.get(val1)[0]
        if TypeVal1 == 'byte':
            srout += '    lhld    ' + val1 + '\n'
            srout += '    mvi     h,$00\n'
        elif TypeVal1 == 'shortint':
            srout += '    lda     ' + val1 + '\n'
            srout += '    mov     l,a\n'
            srout += '    mvi     h,$00\n'
            srout += '    ora     a\n'
            srout += '    jp      Metka_1_' + str(id_op) + '\n'
            srout += '    mvi     h,$FF\n'
            srout += 'Metka_1_' + str(id_op) + ':\n'
        else:
            srout += '    lhld    ' + val1 + '\n'
    return srout

def load_val2(val2, id_op):
    #загрузка в DE
    srout = ''
    if ValueIsNumber(val2):
            srout += '    lxi     d,' + ValueToStr4(val2) + '\n'
    else:
        TypeVal2 = varlist.get(val2)[0]
        if TypeVal2 == 'byte':
            srout += '    lhld    ' + val2 + '\n'
            srout += '    mvi     h,$00\n'
            srout += '    xchg\n'
        elif TypeVal2 == 'shortint':
            srout += '    lda     ' + val2 + '\n'
            srout += '    mov     l,a\n'
            srout += '    mvi     h,$00\n'
            srout += '    ora     a\n'
            srout += '    jp      Metka_2_' + str(id_op) + '\n'
            srout += '    mvi     h,$FF\n'
            srout += 'Metka_2_' + str(id_op) + ':\n'
            srout += '    xchg\n'
        else:
            srout += '    lhld    ' + val2 + '\n'
            srout += '    xchg\n'
    return srout
    
    
def type_if(val1, operation, metka, id_op, val2=''):
    srout = ''
    #если операция унарна
    if len(val2) == 0:
        if ValueIsNumber(val1):
            if operation == '!' and str_to_int(val1) == 0:
                srout += '    jmp     ' + metka + '\n'
            elif operation != '!' and str_to_int(val1) != 0:
                srout += '    jmp     ' + metka + '\n'
        else:
            srout += load_val1(val1, id_op)
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            if operation == '!':
                srout += '    jz      ' + metka + '\n'
            else:
                srout += '    jnz     ' + metka + '\n'
    #если операция бинарна
    else:
        srout += load_val2(val2, id_op)
        srout += load_val1(val1, id_op)
        if operation == '+':
            srout += '    dad     d\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jnz     ' + metka + '\n'
        elif operation == '-':
            srout += '    mov     a,l\n'
            srout += '    sub     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    sbb     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jnz     ' + metka + '\n'
        elif operation == '&':
            srout += '    mov     a,l\n'
            srout += '    ana     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    ana     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jnz     ' + metka + '\n'
        elif operation == '|':
            srout += '    mov     a,l\n'
            srout += '    ora     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    ora     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jnz     ' + metka + '\n'
        elif operation == '^':
            srout += '    mov     a,l\n'
            srout += '    xra     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    xra     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jnz     ' + metka + '\n'
        elif operation == '==':
            srout += '    mov     a,l\n'
            srout += '    sub     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    sbb     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jz      ' + metka + '\n'
        elif operation == '>=':
            srout += '    mov     a,l\n' #из val1 вычитаем val2
            srout += '    sub     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    sbb     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jp      ' + metka + '\n'
        elif operation == '<':
            srout += '    mov     a,l\n' #из val1 вычитаем val2
            srout += '    sub     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    sbb     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jm      ' + metka + '\n'
        elif operation == '>':
            srout += '    xchg\n'
            srout += '    mov     a,l\n' #из val2 вычитаем val1
            srout += '    sub     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    sbb     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jm      ' + metka + '\n'
        elif operation == '<=':
            srout += '    xchg\n'
            srout += '    mov     a,l\n' #из val2 вычитаем val1
            srout += '    sub     e\n'
            srout += '    mov     l,a\n'
            srout += '    mov     a,h\n'
            srout += '    sbb     d\n'
            srout += '    mov     h,a\n'
            #проверка на нуль
            srout += '    mov     a,h\n'
            srout += '    ora     l\n'
            srout += '    jp      ' + metka + '\n'
    return srout

def type_goto(metka):
    srout = ''
    srout += '    jmp     ' + metka + '\n'
    return srout

def type_store(port, value):
    srout = ''
    if port != 'SSPI':
        if ValueIsNumber(value):
            srout += '    mvi     a,' + ValueToStr2(value) + '\n'
            srout += '    out     ' + ValueToStr2(port) + '\n'
        else:
            srout += '    lda     ' + ValueToStr4(value) + '\n'
            srout += '    out     ' + ValueToStr2(port) + '\n'
    else:
        if ValueIsNumber(value):
            srout += '    mvi     a,' + ValueToStr2(value) + '\n'
            srout += '    call    SPI_EX\n'
        else:
            srout += '    lda     ' + ValueToStr4(value) + '\n'
            srout += '    call    SPI_EX\n'
    return srout

def type_load(port, var):
    srout = ''
    if ValueIsNumber(var):
        return srout
    if port != 'SSPI':
        srout += '    in      ' + ValueToStr2(port) + '\n'
        srout += '    sta     ' + ValueToStr4(var) + '\n'
    else:
        srout += '    mvi     a,$FF\n'
        srout += '    call    SPI_EX\n'
        srout += '    sta     ' + ValueToStr4(var) + '\n'
    return srout

def type_delay(value, id_op):
    srout = ''
    if ValueIsNumber(value):
        srout += '    lxi     h,' + ValueToStr4(value) + '\n'
        srout += '    call    DELAY_MS\n'
    else:
        TypeVar = varlist.get(value)[0]
        if TypeVar == 'byte':
            srout += '    lhld    ' + ValueToStr4(value) + '\n'
            srout += '    mvi     h,$00\n'
            srout += '    call    DELAY_MS\n'
        elif TypeVar == 'shortint':
            srout += '    lda     ' + ValueToStr4(value) + '\n'
            srout += '    mvi     h,$00\n'
            srout += '    ora     a\n'
            srout += '    jp      Metka_' + str(id_op) + '\n'
            srout += '    cma\n'
            srout += '    inr     a\n'
            srout += 'Metka_' + str(id_op) + ':\n'
            srout += '    mov     l,a\n'
            srout += '    call    DELAY_MS\n'
        elif TypeVar == 'int':
            srout += '    lhld    ' + ValueToStr4(value) + '\n'
            srout += '    mov     a,h\n'
            srout += '    ora     a\n'
            srout += '    jp      Metka_' + str(id_op) + '\n'
            srout += '    cma\n'
            srout += '    mov     h,a\n'
            srout += '    mov     a,l\n'
            srout += '    cma\n'
            srout += '    mov     l,a\n'
            srout += '    inx     h\n'
            srout += 'Metka_' + str(id_op) + ':\n'
            srout += '    call    DELAY_MS\n'
        else:
            srout += '    lhld    ' + ValueToStr4(value) + '\n'
            srout += '    call    DELAY_MS\n'
    return srout

def type_gr_res(x, y, id_op):
    srout = ''
    srout += load_val1(x, id_op)
    srout += '    push    h\n'
    srout += load_val1(y, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_RES\n'
    return srout
    
def type_gr_bufaddr(addr, id_op):
    srout = ''
    srout += load_val1(addr, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_BUFADDR\n'
    return srout

def type_gr_border(right, left, up, down, id_op):
    srout = ''
    srout += load_val1(right, id_op)
    srout += '    push    h\n'
    srout += load_val1(left, id_op)
    srout += '    push    h\n'
    srout += load_val1(up, id_op)
    srout += '    push    h\n'
    srout += load_val1(down, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_BORDER\n'
    return srout

def type_gr_isstyle(style):
    srout = ''
    if ValueIsNumber(style):
        srout += '    mvi     a,' + ValueToStr2(style) + '\n'
    else:
        srout += '    lda     ' + ValueToStr2(style) + '\n'
    srout += '    push    psw\n'
    srout += '    call    GR_INTERSECTION_STYLE\n'
    return srout

def type_gr_font(font, id_op):
    srout = ''
    srout += load_val1(font, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_FONT\n'
    return srout

def type_gr_sym(hor, vert):
    srout = ''
    if ValueIsNumber(hor):
        srout += '    mvi     a,' + ValueToStr2(hor) + '\n'
    else:
        srout += '    lda     ' + ValueToStr2(hor) + '\n'
    srout += '    push    psw\n'
    if ValueIsNumber(vert):
        srout += '    mvi     a,' + ValueToStr2(vert) + '\n'
    else:
        srout += '    lda     ' + ValueToStr2(vert) + '\n'
    srout += '    push    psw\n'
    srout += '    call    GR_SYM\n'
    return srout

def type_gr_gap(gap):
    srout = ''
    if ValueIsNumber(gap):
        srout += '    mvi     a,' + ValueToStr2(gap) + '\n'
    else:
        srout += '    lda     ' + ValueToStr2(gap) + '\n'
    srout += '    push    psw\n'
    srout += '    call    GR_GAP\n'
    return srout

def type_dot(x, y, id_op):
    srout = ''
    srout += load_val1(x, id_op)
    srout += '    push    h\n'
    srout += load_val1(y, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_DOT\n'
    return srout

def type_wrsym(x, y, sym, id_op):
    srout = ''
    srout += load_val1(x, id_op)
    srout += '    push    h\n'
    srout += load_val1(y, id_op)
    srout += '    push    h\n'
    if ValueIsNumber(sym):
        srout += '    mvi     a,' + ValueToStr2(sym) + '\n'
    else:
        srout += '    lda     ' + ValueToStr2(sym) + '\n'
    srout += '    push    psw\n'
    srout += '    call    GR_WRSYM\n'
    return srout

def type_stopt(addr, x, y, id_op):
    srout = ''
    if (addr[0]=="'" and addr[-1]=="'")or(addr[0]=='"' and addr[-1]=='"'):
        srout += '    jmp     Stopt_' + str(id_op) + '\n'
        srout += 'Srout_str_' + str(id_op) + ':\n'
        addr = addr[1:-1]
        srout += '.db $' + shex2(len(addr)) + '\n'
        for i in range(len(addr)):
            srout += '.db $' + shex2(ord(addr[i])) + '\n'
        srout += 'Stopt_' + str(id_op) + ':\n'
        srout += '    lxi     h,Srout_str_' + str(id_op) + '\n'        
    else:
        srout += load_val1(addr, id_op)
    srout += '    push    h\n'
    srout += load_val1(x, id_op)
    srout += '    push    h\n'
    srout += load_val1(y, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_STOPT\n'
    return srout
    
def type_stmono(addr, x, y, id_op):
    srout = ''
    srout += load_val1(addr, id_op)
    srout += '    push    h\n'
    srout += load_val1(x, id_op)
    srout += '    push    h\n'
    srout += load_val1(y, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_STMONO\n'
    return srout

def type_line(x0, y0, x1, y1, id_op):
    srout = ''
    srout += load_val1(x0, id_op)
    srout += '    push    h\n'
    srout += load_val1(y0, id_op)
    srout += '    push    h\n'
    srout += load_val1(x1, id_op)
    srout += '    push    h\n'
    srout += load_val1(y1, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_LINE\n'
    return srout

def type_circle(x, y, r, id_op):
    srout = ''
    srout += load_val1(x, id_op)
    srout += '    push    h\n'
    srout += load_val1(y, id_op)
    srout += '    push    h\n'
    srout += load_val1(r, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_CIRCLE\n'
    return srout

def type_frame(x0, y0, x1, y1, r, id_op):
    srout = ''
    srout += load_val1(x0, id_op)
    srout += '    push    h\n'
    srout += load_val1(y0, id_op)
    srout += '    push    h\n'
    srout += load_val1(x1, id_op)
    srout += '    push    h\n'
    srout += load_val1(y1, id_op)
    srout += '    push    h\n'
    srout += load_val1(r, id_op)
    srout += '    push    h\n'
    srout += '    call    GR_FRAME\n'
    return srout

    
    
    
    
    
    


def translator(a, memcell_addr, id_start):
    srout = ''
    for i in range(len(a)):
        assembly = False
        if 'ASM' in a[i].upper():
            string = a[i]
            assembly = True
            while not SymOfVar(string[0]):
                string = string[1:]
            srout += string[4:-1] + '\n'
        else:
            string = gapskip(a[i])
        #Выделение меток
        if ':' in string and not assembly:
            e = 0
            metka = ''
            while SymOfVar(string[e]):
                metka += string[e]
                e += 1
            e += 1
            string = string[e:]
            srout += metka + ':\n'
        
        operation = '0'
        equation = False
        if_word = False
        goto_word = False
        byte_word = False
        shortint_word = False
        word_word = False
        int_word = False
        store_word = False
        load_word = False
        delay_word = False
        call_word = False
        ret_word = False
        di_word = False
        ei_word = False
        
        gr_ini_word = False
        gr_res_word = False
        gr_bufaddr_word = False
        gr_border_word = False
        gr_isstyle_word = False
        gr_font_word = False
        gr_sym_word = False
        gr_gap_word = False
        dot_word = False
        wrsym_word = False
        stopt_word = False
        stmono_word = False
        line_word = False
        circle_word = False
        frame_word = False
        #Поиск присвоений
        if not assembly:
            if '=' in string and not '<=' in string and not '>=' in string and not '==' in string:
                equation = True
            #Поиск операций
            if '!' in string:
                operation = '!'
            elif '==' in string:
                operation = '=='
            elif '+' in string:
                operation = '+'
            elif '-'in string:
                operation = '-'
            elif '*'in string:
                operation = '*'
            elif '//'in string:
                operation = '//'
            elif '%'in string:
                operation = '%'
            elif '&'in string:
                operation = '&'
            elif '|'in string:
                operation = '|'
            elif '^'in string:
                operation = '^'
            elif '>'in string:
                operation = '>'
            elif '<'in string:
                operation = '<'
            elif '>='in string:
                operation = '>='
            elif '<='in string:
                operation = '<='
            #Поиск ключевых слов
            if 'IF' in string.upper():
                if_word = True
            if 'GOTO' in string.upper():
                goto_word = True
            if 'BYTE' in string.upper():
                byte_word = True
            if 'SHORTINT' in string.upper():
                shortint_word = True
            if 'WORD' in string.upper():
                word_word = True
            if 'INT' in string.upper():
                int_word = True
            if 'OUT' in string.upper():
                store_word = True
            if 'LOAD' in string.upper():
                load_word = True
            if 'DELAY' in string.upper():
                delay_word = True
            if 'CALL' in string.upper():
                call_word = True
            if 'RET' in string.upper():
                ret_word = True
            if 'DI' in string.upper():
                di_word = True
            if 'EI' in string.upper():
                ei_word = True
        
            if 'GR_INI' in string.upper():
                gr_ini_word = True
            if 'GR_RES' in string.upper():
                gr_res_word = True
            if 'GR_BUFADDR' in string.upper():
                gr_bufaddr_word = True
            if 'GR_BORDER' in string.upper():
                gr_border_word = True
            if 'GR_ISSTYLE' in string.upper():
                gr_isstyle_word = True
            if 'GR_FONT' in string.upper():
                gr_font_word = True
            if 'GR_SYM' in string.upper():
                gr_sym_word = True
            if 'GR_GAP' in string.upper():
                gr_gap_word = True
            if 'DOT' in string.upper():
                dot_word = True
            if 'WRSYM' in string.upper():
                wrsym_word = True
            if 'STOPT' in string.upper():
                stopt_word = True
            if 'STMONO' in string.upper():
                stmono_word = True
            if 'LINE' in string.upper():
                line_word = True
            if 'CIRCLE' in string.upper():
                circle_word = True
            if 'FRAME' in string.upper():
                frame_word = True
        
        
        #Распознавание операций
        ### IF ############################################################################
        if if_word == True and goto_word == True:
            #Унарная операция без отрицания
            if operation == '0':
                string = string[3:]
                val1 = ''
                e = 0
                #Выделяем переменную. Она может состоять только из цифр, букв и символа '_'
                while SymOfVar(string[e]):
                    val1 += string[e]
                    e += 1
                metka = string[e+5:]
                srout += type_if(val1, operation, metka, id_start+i)
            #Унарная операция отрицания
            if operation == '!':
                string = string[4:]
                val1 = ''
                e = 0
                while SymOfVar(string[e]):
                    val1 += string[e]
                    e += 1
                metka = string[e+5:]
                srout += type_if(val1, operation, metka, id_start+i)
            #Бинарная операция
            else:
                string = string[3:]
                val1 = ''
                val2 = ''
                e = 0
                #Выделяем 1 переменную. Она может состоять только из цифр, букв и символа '_'
                while SymOfVar(string[e]) and not string[e]=='-':
                    val1 += string[e]
                    e += 1
                #Пропускаем операцию
                e += 1
                if not SymOfVar(string[e]) and not string[e]=='-':
                    e += 1
                #Выделяем 2 переменную. Она может состоять только из цифр, букв и символа '_'
                while SymOfVar(string[e]):
                    val2 += string[e]
                    e += 1
                metka = string[e+5:]
                srout += type_if(val1, operation, metka, id_start+i, val2)
        
        ### GOTO ###########################################################################################
        elif goto_word == True:
            #Выделяем метку
            string = string[4:]
            srout += type_goto(string)
        
        ### VAR ############################################################################################
        elif byte_word or shortint_word or int_word or word_word:
            TypeVar = ''
            if byte_word:
                TypeVar = 'byte'
                string = string[4:]
            elif shortint_word:
                TypeVar = 'shortint'
                string = string[8:]
            elif int_word:
                TypeVar = 'int'
                string = string[3:]
            else:
                TypeVar = 'word'
                string = string[4:]
            #если нет присвоения
            if not equation:
                srout += type_var(string, TypeVar, memcell_addr, id_start+i)
            #если присвоение
            else:
                var = ''
                e = 0
                #Выделяем переменную. Она может состоять только из цифр, букв и символа '_'
                while SymOfVar(string[e]):
                    var += string[e]
                    e += 1
                #Пропускаем операцию
                e += 1
                if not SymOfVar(string[e]) and not string[e]=='-':
                    e += 1
                value = string[e:]
                srout += type_var(var, TypeVar, memcell_addr, id_start+i, value)
            #Инкремент memcell_addr
            if TypeVar == 'byte' or TypeVar == 'shortint':
                memcell_addr += 1
            else:
                memcell_addr += 2
        
        ### EQUATION UNARY ############################################################################
        elif equation and (operation == '0' or operation == '!'):
            val1 = ''
            val2 = ''
            e = 0
            #Выделяем выхлдную переменную. Она может состоять только из цифр, букв и символа '_'
            while SymOfVar(string[e]):
                val1 += string[e]
                e += 1
            #Пропускаем знак =
            e += 1
            #Пропускаем !, если есть
            if string[e] == '!':
                e += 1
            
            #Выделяем переменную. Она может состоять только из цифр, букв и символа '_'
            val2 += string[e:]
            srout += type_set(val1, val2, operation, id_start+i)
        
        ### EQUATION BINARY ###########################################################################
        elif equation and operation != '0' and operation != '!':
            var_out = ''
            val1 = ''
            val2 = ''
            e = 0
            #Выделяем выхлдную переменную. Она может состоять только из цифр, букв и символа '_'
            while SymOfVar(string[e]):
                var_out += string[e]
                e += 1
            #Пропускаем знак =
            e += 1
            #Выделяем 1 переменную. Она может состоять только из цифр, букв и символа '_'
            val1 += string[e]
            e += 1
            while SymOfVar(string[e]):
                val1 += string[e]
                e += 1
            #Пропускаем операцию
            e += 1
            if not SymOfVar(string[e]) and not string[e]=='-':
                e += 1
            #Выделяем 2 переменную. Она может состоять только из цифр, букв и символа '_'
            val2 = string[e:]
            #
            srout += type_math(var_out, val1, val2, operation, id_start+i)
        
        ### OUT #######################################################################################
        elif store_word:
            string = string[3:]
            port = ''
            value = ''
            e = 0
            #Выделяем port. Он может состоять только из цифр, букв и символа '_'
            port += string[e]
            e += 1
            while SymOfVar(string[e]):
                port += string[e]
                e += 1
            #Пропуск запятой
            e += 1   
            #Выделяем значение
            value = string[e:]
            srout += type_store(port, value)
        
        ### LOAD ########################################################################################
        elif load_word:
            string = string[4:]
            port = ''
            value = ''
            e = 0
            #Выделяем port. Он может состоять только из цифр, букв и символа '_'
            port += string[e]
            e += 1
            while SymOfVar(string[e]):
                port += string[e]
                e += 1
            #Пропуск запятой
            e += 1   
            #Выделяем значение
            value = string[e:]
            srout += type_load(port, value)
        
        ### DELAY #######################################################################################
        elif delay_word:
            value = string[6:-1]
            srout += type_delay(value, id_start+i)
        
        ### CALL ########################################################################################
        elif call_word: #call(metka);
            srout += '    call    ' + string[5:-1] + '\n'
        ### RET #########################################################################################
        elif ret_word: #ret();
            srout += '    ret\n'
        ### DI ##########################################################################################
        elif di_word: #di();
            srout += '    di\n'
        ### EI ##########################################################################################
        elif ei_word: #ei();
            srout += '    ei\n'
        
        ### GR_INI ######################################################################################
        elif gr_ini_word:
            srout += '    call    GR_INI\n'
        
        ### GR_RES ######################################################################################
        elif gr_res_word:
            string = string[7:-1]
            locarr = string.split(',')
            srout += type_gr_res(locarr[0], locarr[1], id_start+i)
        
        ### GR_BUFADDR ##################################################################################
        elif gr_bufaddr_word:
            string = string[11:-1]
            srout += type_gr_bufaddr(string, id_start+i)
        
        ### GR_BORDER ###################################################################################
        elif gr_border_word:
            string = string[10:-1]
            locarr = string.split(',')
            srout += type_gr_border(locarr[0], locarr[1], locarr[2], locarr[3], id_start+i)
        
        ### GR_ISSTYLE ##################################################################################
        elif gr_isstyle_word:
            string = string[11:-1]
            srout += type_gr_isstyle(string)
        
        ### GR_FONT #####################################################################################
        elif gr_font_word:
            string = string[8:-1]
            srout += type_gr_font(string, id_start+i)
        
        ### GR_SYM ######################################################################################
        elif gr_sym_word:
            string = string[7:-1]
            locarr = string.split(',')
            srout += type_gr_sym(locarr[0], locarr[1])
        
        ### GR_GAP ######################################################################################
        elif gr_gap_word:
            string = string[7:-1]
            srout += type_gr_gap(string)
        
        ### DOT #########################################################################################
        elif dot_word:
            string = string[4:-1]
            locarr = string.split(',')
            srout += type_dot(locarr[0], locarr[1], id_start+i)
        
        ### WRSYM #######################################################################################
        elif wrsym_word:
            string = string[6:-1]
            locarr = string.split(',')
            srout += type_wrsym(locarr[0], locarr[1], locarr[2], id_start+i)
        
        ### STOPT #######################################################################################
        elif stopt_word:
            string = string[6:-1]
            locarr = string.split(',')
            srout += type_stopt(locarr[0], locarr[1], locarr[2], id_start+i)
        
        ### STMONO ######################################################################################
        elif stmono_word:
            string = string[7:-1]
            locarr = string.split(',')
            srout += type_stmono(locarr[0], locarr[1], locarr[2], id_start+i)
        
        ### LINE ########################################################################################
        elif line_word:
            string = string[5:-1]
            locarr = string.split(',')
            srout += type_line(locarr[0], locarr[1], locarr[2], locarr[3], id_start+i)
        
        ### CIRCLE ######################################################################################
        elif circle_word:
            string = string[7:-1]
            locarr = string.split(',')
            srout += type_circle(locarr[0], locarr[1], locarr[2], id_start+i)
        
        ### FRAME #######################################################################################
        elif frame_word:
            string = string[6:-1]
            locarr = string.split(',')
            srout += type_frame(locarr[0], locarr[1], locarr[2], locarr[3], locarr[4], id_start+i)
        
        
        
        
        
    return srout




























global stri
stri = ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']
global varlist
varlist = {}

f = open('/home/victor/EnterB.txt', 'r')
a = f.read().split(';')
f.close()

#a = ['load SSPI, var_a']

print('----------------------------------------------------------------')
print('Генерация мнемонического кода..')
srout = ''
#srout += '    jmp     Start_metka\n'
srout += '.include /home/victor/Desktop/Micron_BIOS/BIOS.asm\n'
srout += 'Start_metka:\n'
#srout += '    call    STANDARTIO_INI\n'
srout += translator(a,0x8200,123456)
srout += '    hlt\n'
print('Сохранение данных')
f = open('/home/victor/Desktop/Enter1.0', 'w')
f.write(srout)
f.close()
print('----------------------------------------------------------------')


