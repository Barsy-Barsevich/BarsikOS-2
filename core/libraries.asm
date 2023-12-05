;Набор стандартных библиотек
;
;-<Начало - F001>---------------------------------------------------------------
    .org    $F001
;-<Функция перехода в режим ОС>-------------------------------------------------
; SYStemFS
; Функция SYS_OS_muutos - переход в режим ОС
; Ввод: нет
; Вывод: нет
; Используемые регистры: A,I
; Оценка: длина - 12 байт, время - ~29 тактов
SYS_OS_muutos:
    mvi     a,40H
    sim
    mvi     a,C0H
    sim
    nop
    nop
    nop
    nop
    nop
    ret

;StandartArithmetic
;Важно отметить, что функции SDIV и UDIV не будут пока работать, тк переход
;в режим ОС не предусматривает сохранения данных регистров
    jmp     SUB16
    jmp     MUL16
    jmp     SDIV16
    jmp     UDIV16
    jmp     CMP16
    jmp     ABS
    jmp     DOPHL
    jmp     DOPBC
    jmp     DOPDE
;AFS3
;Важно отметить, что функции STRCMP, CONCAT, POS не будут пока работать, тк
;переход в режим ОС не предусматривает сохранения данных регистров
    jmp     BITSET
    jmp     BITCLR
    jmp     BITTST
    jmp     MFILL
    jmp     COPCOUNT
    jmp     SYM_IS_DEC
    jmp     SYM_IS_HEX
    jmp     ASCBCD
    jmp     BCDASC
    jmp     ASCSEG7
    jmp     BCDSEG7
    jmp     BN2HEX
    jmp     HEX2BN
    jmp     SYM_LOWER
    jmp     SYM_HIGHER
    jmp     STRCOP
    jmp     STRCMP
    jmp     CONCAT
    jmp     POS
;Левые функции
    jmp     Function
    jmp     Delay_ms_6
    jmp     Read_Time
;Пришедшие от драйверов
    jmp     ST7920_INI
    jmp     ST7920_PRINT_BUF
    jmp     ST7920_BUF_CLR
;Ввод-вывод (потом причесать и оформить в единую библиотеку вместе с задержками)
    jmp     SPI_EX
;Драйвер диска W25
    jmp     W25_SET_BASE_ADDRESS
    jmp     W25_SET_SS_BIT
    jmp     W25_SS_DOWN
    jmp     W25_SS_UP
    jmp     W25_READ_ID
    jmp     W25_SECTOR_WRITE
    jmp     W25_SECTOR_READ
    jmp     W25_SECTOR_ERASE
;Dop
    jmp     W25_Test

.include /home/victor/Desktop/BarsikOS-2/core/systemdef.def
.include /home/victor/Desktop/BarsikOS-2/core/smm.def
.include /home/victor/Desktop/BarsikOS-2/lib/StandartArithmetic.asm
.include /home/victor/Desktop/BarsikOS-2/lib/AFS3.asm
.include /home/victor/Desktop/BarsikOS-2/drive/ST7920_drive.asm
.include /home/victor/Desktop/BarsikOS-2/drive/w25.asm

; (E)  Barsotion KY;
; Стандартный SPI обмен v1.2 (проверено 11.07.23)
; Функция реализует протокол SPI программно. ЭВМ в данном случае выступает
; в роли master'a.
; Выводы порта:
; Порт SSPI_PORT (тип 'С' ИС 8255), инициализирован так, что старшая тетрада
; на ввод, младшая на вывод.
; С(0) -- MOSI
; С(1) -- CLK
; С(7) -- MISO
; Ввод:    А (передаваемые данные)
; Вывод:   А (принимаемые данные)
; Используемые регистры: А, B, C
; Используемая память: нет
; Длина: 31 байт
; Время выполнения: 812 (+-4) тактов.

SPI_EX:
;регистр С - счетчик
    mvi     c,08H
spi_1:
;сдвиг data влево, сдвинутый бит в 0й разряд B (это будет MOSI)
    add     a
    push    psw
    mvi     a,00H
    ral
    mov     b,a
;выводим MOSI в порт SSPI_PORT, CLK равен 0
    in      SSPI_PORT
    ani     FDH             ;очистка CLK
    out     SSPI_PORT
    ani     FCH             ;очистка CLK и MOSI
    ora     b               ;загрузка MOSI
    out     SSPI_PORT
;поднимаем CLK и выводим вместе с ним
    ori     02H
    out     SSPI_PORT
;байт данных в B
    pop     psw
    mov     b,a
;читаем порт SSPI_PORT, бит MISO во флаг переноса
    in      SSPI_PORT
    add     a
;добавляем MISO к data, заместо пустого старшего бита
    mov     a,b
    aci     00H
;счетчик
    dcr     c
    jnz     spi_1
    mov     b,a
;опускаем CLK и поднимаем MOSI
    in      SSPI_PORT
    ani     FDH
    ori     01H
    out     SSPI_PORT
    mov     a,b
    ret
    
; (E) Barsotion KY
; Функция Delay_ms_6_ - программная задержка
; t = (6001*HL)/fтакт мс
; t = HL миллисекунд при fтакт = 6.0 МГц
; Ввод:    HL (время в мс)
; Вывод:   нет
; Используемые регистры: АF,DE,HL
; Используемая память: нет
; Длина: 16 байт
; Время выполнения: ~HL мкс при тактовой частоте 6MHz
Delay_ms_6:
    lxi     d,$00F9
delay_ms_6_1:
    dcx     d
    mov     a,d
    ora     e
    jnz     delay_ms_6_1
    dcx     h
    mov     a,h
    ora     l
    jnz     Delay_ms_6
    ret


    
Function:
    call    SYS_OS_muutos
    lda     $8010
;    ani     $0F
;    call    BCDSEG7
    cma
    out     DISP_PORT
    ret

Read_Time:
    call    SYS_OS_muutos
;Send code to latch counting
    mvi     a,$00
    out     TIMER_MODEREG
    in      TIMER_COUNTER_0
    mov     e,a
    in      TIMER_COUNTER_0
    mov     d,a
    mov     a,e
    rar
    rar
    rar
    call    BCDSEG7
    cma
    out     DISP_PORT
    ret

W25_Test:
    call    SYS_OS_muutos
    lxi     h,W25_Handle_TypeDef
    push    h
    call    W25_SET_BASE_ADDRESS
    mvi     a,$04
    push    psw
    call    W25_SET_SS_BIT
;Signal

;;(2)Тест подключения диска по Manufacturer ID
;    call    W25_READ_ID
;    pop     h
;    mov     a,h
;    out     DISP_PORT
;    ret

;;(1)Тест вывода SS
;metka_c:
;    call    W25_SS_UP
;    lxi     h,$01F4
;    call    Delay_ms_6
;    call    W25_SS_DOWN
;    lxi     h,$01F4
;    call    Delay_ms_6
;    jmp     metka_c

;    lxi     h,$0000
;    push    h
;    call    W25_SECTOR_ERASE
;    lxi     h,$0000 ;сектор номер 0
;    push    h
;    lxi     h,$0000 ;буфер начиная с адреса $0000
;    push    h
;    call    W25_SECTOR_WRITE
    
;Стирание кластера 0 диска
    lxi     h,$0000
    push    h
    call    W25_SECTOR_ERASE
;Стирание кластера 1 диска
    lxi     h,$0001
    push    h
    call    W25_SECTOR_ERASE
;Заполнение сектора А ОЗУ значением $00
    lxi     h,$A000
    lxi     d,$1000
    xra     a
    call    MFILL    
;Запись блока F ОЗУ в кластер 0 диска
    lxi     h,$0000
    push    h
    lxi     h,$F000
    push    h
    call    W25_SECTOR_WRITE
;Чтение кластера 0 диска в сектор A ОЗУ
    lxi     h,$0000
    push    h
    lxi     h,$A000
    push    h
    call    W25_SECTOR_READ
;Запись сектора A ОЗУ в кластер 1 диска
    lxi     h,$0001
    push    h
    lxi     h,$A000
    push    h
    call    W25_SECTOR_WRITE
;Стереть кластер 0 диска
    lxi     h,$0000
    push    h
    call    W25_SECTOR_ERASE
;Запись сектора 0 ОЗУ в кластер 0 диска
    lxi     h,$0000
    push    h
    lxi     h,$0000
    push    h
    call    W25_SECTOR_WRITE

;Чтение ID
    call    W25_READ_ID
    pop     h
    mov     a,h
    out     DISP_PORT
;Задержка
    lxi     h,$1000
    call    Delay_ms_6
    ret
