; Levental-Seivill
; AFS3 - Библиотека дополнительных универсальных функций
; (08.11.2023)

;Битовые операции
;  BITSET - установка разряда
;  BITCLR - очистка разряда
;  BITTST - проверка разряда
;Работа с массивами
;  MFILL - заполнение памяти
;  COPCOUNT - копирование массивов памяти
;Операции преобразования типов
;  SYM_IS_DEC - проверка ASCII-цифры на десятичность
;  SYM_IS_HEX - проверка ASCII-цифры на шестнадцатиричность
;  ASCBCD - преобразование цифры в коде ASCII в код BCD
;  BCDASC - преобразование цифры в коде BCD в код ASCII
;  ASCSEG7 - преобразование 16-цифры в коде ASCII в семисегментный код
;  BCDSEG7 - преобразование 16-цифры в коде BCD в семисегментный код
;  BN2HEX - преобразование двоичных данных в шестнадцитиричные
;  HEX2BN - преобразование шестнадцатиричных данных в коде ASCII
;  SYM_LOWER - перевод буквы в нижний регистр
;  SYM_HIGHER - перевод буквы в верхний регистр
;Операции над строками
;  STRCOP - копирование строк
;  STRCMP - сравнение строк
;  CONCAT - объединение строк
;  POS - нахождение адреса подстроки в строке

;.def strcmp_lens1 =     $FFFC ;byte
;.def strcmp_lens2 =     $FFFB ;byte
;.def concat_s1adr =     $FFF9 ;word
;.def concat_s1len =     $FFF8 ;byte
;.def concat_s2len =     $FFF7 ;byte
;.def concat_strgov =    $FFF6 ;byte
;.def pos_string =       $FFF4 ;word
;.def pos_substg =       $FFF2 ;word
;.def pos_slen =         $FFF1 ;byte
;.def pos_sublen =       $FFF0 ;byte
;.def pos_index =        $FFEF ;byte

;
; Функция BITSET - установка разряда
;
; Ввод: B (исходное число), A (номер разряда 2-1-0)
; Вывод: A (B с установленным разрядом)
;
; Используемые регистры: AF,BС,HL
; Используемая память: нет
;
; Длина: 20 байт
; Время выполнения: 59 тактов
;
; Начало кода:

BITSET:
    ani     07H
    mov     c,a
    mov     a,b
    lxi     h,bitset_msk
    mvi     b,00h
    dad     b
    ora     m
    ret
bitset_msk:
    .db 01h
    .db 02h
    .db 04h
    .db 08h
    .db 10h
    .db 20h
    .db 40h
    .db 80h
    
;
; Функция BITCLR - очистка разряда
;
; Ввод: B (исходное число), A (номер разряда 2-1-0)
; Вывод: A (B с отчищенным разрядом)
;
; Используемые регистры: AF,BС,HL
; Используемая память: нет
;
; Длина: 20 байт
; Время выполнения: 59 тактов
;
; Начало кода:

BITCLR:
    ani     07H
    mov     c,a
    mov     a,b
    lxi     h,bitclr_msk
    mvi     b,00h
    dad     b
    ana     m
    ret
bitclr_msk:
    .db FEh
    .db FDh
    .db FBh
    .db F7h
    .db EFh
    .db DFh
    .db BFh
    .db 7Fh
    
;
; Функция BITTST - проверка разряда
;
; Ввод: B (исходное число), A (номер разряда 2-1-0)
; Вывод: Z=1 - разряд очищен
;        Z=0 - разряд установлен
;
; Используемые регистры: AF,BС,HL
; Используемая память: нет
;
; Длина: 20 байт
; Время выполнения: 59 тактов
;
; Начало кода:

BITTST:
    ani     07H
    mov     c,a
    mov     a,b
    lxi     h,bitset_msk
    mvi     b,00h
    dad     b
    ana     m
    ret
    
;
; Функция MFILL - заполнение памяти
;
; Ввод:  Адрес начала - HL
;        Размер области - DE
;        Значение, помещаемое в память - A
; Вывод: нет
;
; Используемые регистры: AF,С,DE,HL
; Используемая память: нет
;
; Длина: 10 байт
; Время выполнения: DE*37+11
;
; Начало кода:

MFILL:
    mov     c,a
mfill-loop:
    mov     m,c
    inx     h
    dcx     d
    mov     a,e
    ora     d
    jnz     mfill-loop
    ret

;
; Функция COPCOUNT - копирование массивов памяти
; Ввод: HL - адрес "куда копируем"
;       DE - адрес "откуда копируем"
;       BC - количество копируемых ячеек памяти
; Вывод: нет
; Используемые регистры: все
; Длина: 15 байт
; Время выполнения: -
COPCOUNT:
    inr     b
    inr     c
str_copcount_1:
    dcr     c
    jnz     str_copcount_2
    dcr     b
    rz
str_copcount_2:
    ldax    d
    mov     m,a
    inx     h
    inx     d
    jmp     str_copcount_1
    

; Функция SYM_IS_DEC - проверка значения ASCII, является ли десятичной цифрой
; Ввод: A
; Вывод: (CY=0) - не является цифрой, (CY=1) - является десятичной цифрой
; Используемые регистры: F
; Оценка: длина - 7 байт, время - 
SYM_IS_DEC:
;Если больше 39H, return (CY=0)
    cpi     $3A
    rnc
;Если меньше 30H, return (CY=0). Иначе return (CY=1)
    cpi     $30
    cmc
    ret


; Функция SYM_IS_HEX - проверка значения ASCII, является ли шестнадцатиричной цифрой
; Ввод: A
; Вывод: (CY=0) - не является цифрой, (CY=1) - является шестнадцатиричной цифрой
; Используемые регистры: F
; Используемые функции:
;   - SYM_IS_DEC
; Оценка: длина - 11 байт, время - 
SYM_IS_HEX:
    call    SYM_IS_DEC
    rc
;Если больше 46H, return (CY=0)
    cpi     $47
    rnc
;Если меньше 41H, return (CY=0). Иначе return (CY=1)
    cpi     $41
    cmc
    ret


; Функция ASCBCD - преобразование кода ASCII в BCD
; Ввод: A (код ASCII)
; Вывод: (CY=1) - успешно, A (данные BCD)
;        (CY=0) - неудачно, A (исходные данные)
; Используемые регистры: AF
; Оценка: длина - 13 байт, время - 
ASCBCD:
    call    SYM_IS_HEX
    rnc
    sui     30H
    cpi     0AH
    rc
    sui     07H
    stc
    ret

; Функция BCDASC - преобразование кода BCD в ASCII
; Ввод: A
; Вывод: A
; Используемые регистры:
; Оценка: длина - 10 байт, время - 
BCDASC:
    ani     0FH ;защита от дурака
    adi     30H
    cpi     3AH
    rm
    adi     07H
    ret


; Функция ASCSEG7 - преобразование шестнадцатиричной цифры в коде ASCII в
; семисегментный код
; Функция BCDSEG7 - преобразование шестнадцатиричной цифры в BCD-коде в 
; семисегментный код
; Ввод: A
; Вывод: A (функция ASCSEG7, если введенное значение не шестнадцатиричная
; цифра, возвращает '-')
; Формат выходных данных:
; | 7|6|5|4|3|2|1|0|
; |DP|G|F|E|D|C|B|A|
; Используемые регистры: AF,BC
; Оценка: длина - 31 байт
ASCSEG7:
    call    ASCBCD
    jc      bcdseg7_1
    mvi     a,$40   ;'-'
    ret
BCDSEG7:
    ani     $0F
bcdseg7_1:
    lxi     b,STR_7seg
    add     c
    mov     c,a
    ldax    b
    ret
STR_7seg:
    .db     3FH     ;'0'
    .db     06H     ;'1'
    .db     5BH     ;'2'
    .db     4FH     ;'3'
    .db     66H     ;'4'
    .db     6DH     ;'5'
    .db     7DH     ;'6'
    .db     07H     ;'7'
    .db     7FH     ;'8'
    .db     6FH     ;'9'
    .db     77H     ;'A'
    .db     7CH     ;'B'
    .db     58H     ;'C'
    .db     5EH     ;'D'
    .db     79H     ;'E'
    .db     71H     ;'F'


; Функция BN2HEX - преобразование двоичных данных в шестнадцитиричные
; в коде ASCII
; Ввод: A
; Вывод: H - ст цифра, L - мл цифра
; Используемые регистры: АF,B,HL
; Используемая память: нет
; Длина: 29 байт
; Время выполнения: ~160 + 4 для каждой недесятичной цифры тактов
BN2HEX:
; Преобразовать старшую половину в код ASCII
    mov     b,a    ;сохранить начальное значение
    ani     $F0    ;взять ст половину
    rrc            ;переслать ст половину в мл
    rrc
    rrc
    rrc
    call    bn2hex_nascii   ;преобразовать ст половину в код ASCII
    mov     h,a        ;возвратить в H
; Преобразовать младшую половину в код ASCII
    mov     a,b
    ani     $0F
    call    bn2hex_nascii
    mov     l,a        ;возвратить мл половину в H
    ret
; Подпрограмма nascii преобразует шестнадцатиричную цифру в символ
; в коде ASCII.
; Вход:  А - двоичное число в мл половине байта
; Выход: А - символ в коде ASCII
; Используемые регистры - AF
bn2hex_nascii:
    cpi     $0A
    jc      bn2hex_nas1
    adi     $07
bn2hex_nas1:
    adi     $30
    ret


; Функция HEX2BN - преобразование шестнадцатиричных данных в коде ASCII
; в двоичные
; Ввод: H - ст цифра, L - мл цифра
; Вывод: A
; Используемые регистры: АF,B
; Используемая память: нет
; Длина: 25 байт
; Время выполнения: 126 + 10 для каждой недесятичной цифры тактов
HEX2BN:
    mov     a,l           ;взять мл символ
    call    hex2bn_a2hex  ;преобразовать в шест цифру
    mov     b,a           ;сохранить шест значение в В
    mov     a,h           ;взять ст символ
    call    hex2bn_a2hex  ;преобразовать в шест цифру
    rlc                   ;сдвинуть на 4 разряда
    rlc
    rlc
    rlc
    ora     b   ;"ИЛИ" с мл
    ret
; Подпрограмма a2hex
; Превращает цифру в коде ASCII в шестнадцатиричную
; Вход А
; Выход А
hex2bn_a2hex:
    sui     $30
    cpi     $0A
    rc
    sui     $07
    ret


; Функция SYM_LOWER - перевод буквы в нижний регистр
; Ввод: A (исходное значение ASCII)
; Вывод: A (значение ASCII)
; Используемые регистры: AF
; Длина: -
; Время выполнения: -
SYM_LOWER:
;Возврат, если меньше $41
    cpi     $41
    rm
;Возврат, если больше или равно $5B
    cpi     $5B
    rp
;Рассматриваемый код - буква. Увеличить значение на $20
    adi     $20
    ret


; Функция SYM_HIGHER - перевод буквы в верхний регистр
; Ввод: A (исходное значение ASCII)
; Вывод: A (значение ASCII)
; Используемые регистры: AF
; Длина: -
; Время выполнения: -
SYM_HIGHER:
;Возврат, если меньше $61
    cpi     $61
    rm
;Возврат, если больше или равно $7B
    cpi     $7B
    rp
;Рассматриваемый код - буква. Уменьшить значение на $20
    sui     $20
    ret
    

; Функция STRCOP - копирование строк
; Ввод: HL (базовый адрес строки-источника)
;       DE (базовый адрес "куда копируем")
; Вывод: нет
; Используемые регистры: AF,C,DE,HL
; Длина: 12 байт
; Время выполнения: -
STR_COP:
;copy DE to HL
    ldax d
    mov     c,a
    inr     c
str_cop_1:
    ldax    d
    mov     m,a
    inx     d
    inx     h
    dcr     c
    jnz     str_cop_1
    ret


; Функция STRCMP - сравнение строк
; Ввод: HL (базовый адрес str1)
;       DE (базовый адрес str2)
; Вывод: Z=1 - str1=str2
;        Z=0 - str1!=str2
;        C=1 - str1<str2
;        C=0 - str1>=str2
; Используемые регистры: AF,B,DE,HL
; Используемая память: 2 ячейки в любой обл ОЗУ
;  - strcmp_lens1 (byte)
;  - strcmp_lens2 (byte)
; Длина: 36 байт
; Время выполнения: 52*(ДЛИНА САМОЙ КОРОТКОЙ СТРОКИ)+113+18
STRCMP:
    ldax    d
    sta     strcmp_lens2
    cmp     m
    jc      strcmp_begcmp
    mov     a,m
strcmp_begcmp:
    ora     a
    jz      strcmp_cmplen
    mov     b,a
    xchg
    ldax    d
    sta     strcmp_lens1
strcmp_cmplp:
    inx     d
    inx     h
    ldax    d
    cmp     m
    rnz
    dcr     b
    jnz     strcmp_cmplp
strcmp_cmplen:
    lda     strcmp_lens1
    lxi     h,strcmp_lens2
    cmp     m
    ret


; Функция CONCAT - объединение строк
; Строка 2 присоединяется к строке 1, при этом строка 1 соотв увеличивается.
; Если длина результ строки превышает максимальную, присоединяется только та часть строки 2, которая позволяет получитьь строку 1 максимальной длины.
; Ели какая-то часть строки 2 получается отброшена, устанавливается флаг С.
; Ввод: HL (базовый адрес str1)
;       DE (базовый адрес str2)
;       B (макс. длина строки 1)
; Вывод: измененная строка 1
;        С=1 - часть строки 2 была отброшена
;        С=0 - часть строки 2 не была отброшена
; Используемые регистры: все
; Используемая память: 5 байт в любой обл. ОЗУ
;  - concat_s1adr (word)
;  - concat_s1len (byte)
;  - concat_s2len (byte)
;  - concat_strgov (byte)
; Длина: 83 байта
; Время выполнения: 40*(ЧИСЛО ПРИСОЕДИНЯЕМЫХ СИМВОЛОВ)+265+18
CONCAT:
    shld    concat_s1adr
    push    b
    mov     a,m
    sta     concat_s1len
    mov     c,a
    mvi     b,00H
    dad     b
    ldax    d
    sta     concat_s2len
    pop     b
    mov     c,a
    lda     concat_s1len
    add     c
    jc      concat_toolng
    cmp     b
    jz      concat_lenok
    jc      concat_lenok
concat_toolng:
    mvi     a,FFH
    sta     concat_strgov
    lda     concat_s1len
    mov     c,a
    mov     a,b
    sub     c
    rc
    sta     concat_s2len
    mov     a,b
    sta     concat_s1len
    jmp     concat_docat
concat_lenok:
    sta     concat_s1len
    sub     a
    sta     concat_strgov
concat_docat:
    lda     concat_s2len
    ora     a
    jz      concat_exit
    mov     b,a
concat_catlp:
    inx     h
    inx     d
    ldax    d
    mov     m,a
    dcr     b
    jnz     concat_catlp
concat_exit:
    lda     concat_s1len
    lhld    concat_s1adr
    mov     m,a
    lda     concat_strgov
    rar
    ret


; Функция POS - нахождение адреса подстроки в строке
; Ищет первое появление подстроки в строке и возвращает ее начальный индекс.
; Если подстрока не найдена, возвращает 0
; Ввод: HL (базовый адрес строки)
;       DE (базовый адрес подстроки)
; Вывод: A
; Используемые регистры: все
; Используемая память: 7 байт в любой обл. ОЗУ
;  - pos_string (word)
;  - pos_substg (word)
;  - pos_slen (byte)
;  - pos_sublen (byte)
;  - pos_index (byte)
POS:
    shld    pos_string
    xchg
    mov     a,m
    ora     a
    jz      pos_notfnd
    inx     h
    shld    pos_substg
    sta     pos_sublen
    mov     c,a
    ldax    d
    ora     a
    jz      pos_notfnd
    sub     c
    jc      pos_notfnd
    inr     a
    mov     c,a
    sub     a
    sta     pos_index
pos_slp1:
    lxi     h,pos_index
    inr     m
    lda     pos_sublen
    mov     b,a
    lhld    pos_substg
    xchg
    lhld    pos_string
    inx     h
    shld    pos_string
pos_cmplp:
    ldax    d
    cmp     m
    jnz     pos_slp2
    dcr     b
    jz      pos_found
    inx     h
    inx     d
    jmp     pos_cmplp
pos_slp2:
    dcr     c
    jnz     pos_slp1
    jz      pos_notfnd
pos_found:
    lda     pos_index
    ret
pos_notfnd:
    sub     a
    ret



