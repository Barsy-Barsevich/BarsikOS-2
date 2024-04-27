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
;GRLIBUSR
    jmp     GR_INI_USR
    jmp     GR_RESOLUTION_USR
    jmp     GR_START_BUF_ADDR_USR
    jmp     GR_BORDER_USR
    jmp     GR_ISSTYLE_USR
    jmp     GR_FONT_USR
    jmp     GR_SYM_PARAMETERS_USR
    jmp     GR_GAP_USR
    jmp     GR_DOT_USR
    jmp     GR_WRSYM_USR
    jmp     GR_STOPT_USR
    jmp     GR_STMONO_USR
    jmp     GR_LINE_USR
    jmp     GR_CIRCLE_USR
    jmp     GR_FRAME_USR
;Ужасная подстава, функция SYStemFS
    jmp     SYS_User_muutos

.include /home/victor/Desktop/BarsikOS-2/core/systemdef.def
.include /home/victor/Desktop/BarsikOS-2/core/smm.def
.include /home/victor/Desktop/BarsikOS-2/lib/StandartArithmetic.asm
.include /home/victor/Desktop/BarsikOS-2/lib/AFS3.asm
.include /home/victor/Desktop/BarsikOS-2/drive/ST7920_drive.asm
.include /home/victor/Desktop/BarsikOS-2/drive/w25.asm
.include /home/victor/Desktop/BarsikOS-2/drive/fat_main.asm
.include /home/victor/Desktop/BarsikOS-2/drive/GRLIBUSR.ASM


; SYStemFS
; Функция SYS_User_muutos - переход в режим пользователя
; Ввод: нет
; Вывод: нет
; Используемые регистры: все
; Используемые порты: таймер номер 2
; Оценка: длина - 23 байта, время - 123 такта
SYS_User_muutos:
;Настройка таймера
    mvi     a,B0H
    out     TIMER_MODEREG
    lhld    SYSCELL_QUANT_TIME
    mov     a,l
    out     TIMER_COUNTER_2
    mov     a,h
    out     TIMER_COUNTER_2
; Включаем режим пользователя
    mvi     a,40H
    sim
    mvi     a,C0H
    sim
    pop     h
    pop     d
    pop     b
    pop     psw
    ret
    

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
    
;(A) - input
SendData:
    mov     b,a
    ani     $0F
    out     EXTPORT_B
    adi     $80
    out     EXTPORT_B
    sui     $80
    out     EXTPORT_B
    lxi     h,$0010
    call    Delay_ms_6
    mov     a,b
    ani     $F0
    rrc
    rrc
    rrc
    rrc
    out     EXTPORT_B
    adi     $80
    out     EXTPORT_B
    sui     $80
    out     EXTPORT_B
    lxi     h,$0010
    call    Delay_ms_6
    xra     a
    out     EXTPORT_B
    ret


W25_Test:
    call    SYS_OS_muutos
;    lxi     h,W25_Handle_TypeDef
;    push    h
;    call    W25_SET_BASE_ADDRESS
;    mvi     a,$04
;    push    psw
;    call    W25_SET_SS_BIT
;    lxi     h,$A000
;    shld    SYSCELL_DISKBUF_ADDR
;
;    call    W25_READ_ID
;    pop     h
;    mov     a,h
;    out     DISP_PORT
;;Загрузка адреса строки
;    lxi     h,String_Name
;    push    h
;;Номер начального кластера директории, в которой ведем поиск
;    lxi     h,$0002
;    push    h
;    call    FAT_FIND_BY_NAME
;;Статус исследуемого файла
;    pop     psw
;;Выгружаем номер первого кластера найденного файла/субдиректории
;    pop     h
;;Читаем данный кластер
;    push    h
;    
;    mov     a,l
;    call    BCDSEG7
;    cma
;    out     DISP_PORT
;    
;    lxi     h,$9000
;    push    h
;    call    DISK_CLUSTER_READ
;
;***Test FBP *******************************************************************
;    lxi     h,StringPat
;    push    h
;    call    FAT_FBP
;    pop     psw
;    mvi     a,$08
;    call    BCDSEG7
;    cma
;    out     DISP_PORT
;*******************************************************************************
;
;    call    FAT_SPR
;;Загрузка адреса строки
;    lxi     h,String_Name
;    push    h
;;Номер начального кластера директории, в которой ведем поиск
;    ;lxi     h,$0002
;    lhld    SYSCELL_FAT_POINTER
;    push    h
;    call    FAT_FIND_BY_NAME
;;Статус исследуемого файла
;    pop     psw
;;Выгружаем номер первого кластера найденного файла/субдиректории
;    pop     h
;    shld    SYSCELL_FAT_POINTER
;
;    lhld    SYSCELL_FAT_POINTER
;    push    h
;    lxi     h,$9000
;    push    h
;    call    DISK_CLUSTER_READ
;    lda     $8010
;    cpi     $CF
;    rz
;    lxi     h,$0008     ;начальный кластер программы
;    push    h
;    lxi     h,$1000
;    push    h
;    call    DISK_CLUSTER_READ

;    lda     $8001
;    cpi     $CF
;    jz      otladka
;    mvi     a,$CF
;    sta     $8001
;    
;    call    SYS_CreateNewProcess
     
;    lhld    SYSCELL_SAP_STARTADDR
;    lxi     d,$0020
;    dad     d
;    push    h
;    ldhi    SYSPA_RETADDR
;    lxi     h,$3000
;    shlx
;    pop     h
;    push    h
;    ldhi    SYSPA_SP_REG
;    lxi     h,$3FFF
;    shlx
;    pop     h
;    push    h
;    ldhi    SYSPA_TA_01
;    mvi     a,$03
;    stax    d
;    inx     d
;    mvi     a,$33
;    stax    d
;    inx     d
;    mvi     a,$33
;    stax    d
;    inx     d
;    mvi     a,$33
;    stax    d
;    inx     d
;    mvi     a,$33
;    stax    d
;    inx     d
;    mvi     a,$33
;    stax    d
;    inx     d
;    mvi     a,$33
;    stax    d
;    inx     d
;    mvi     a,$3F
;    stax    d
    
    ;Необходимо завершить тесты. Панелька ПЗУ на плате сломалась. Вселенская подстава не хочет, чтобы я написал эту функцию, но я должен ее написать
    
;    pop     h
    
otladka:
    mvi     a,$CD
    sta     $3000
    mvi     a,$67
    sta     $3001
    mvi     a,$F0
    sta     $3002
    mvi     a,$C3
    sta     $3003
    mvi     a,$00
    sta     $3004
    mvi     a,$30
    sta     $3005
    
    ret


StringPat:
.db $10
.ds 'SUBDIR1/UWFB.BIN'


;Создать новый процесс
SYS_CreateNewProcess:    
;(1) Инкремент количества процессов
    lda     SYSCELL_NUM_OF_PROC
    mov     e,a
    inr     a
    sta     SYSCELL_NUM_OF_PROC
;(2) Получение начального адреса дескриптора нового процесса
    xra     a
    mov     d,a
    rdel
    rdel
    rdel
    rdel
    rdel
    lhld    SYSCELL_SAP_STARTADDR
    dad     d
    push    h
;(3) Вычислить ID как max(IDs)+1
    mvi     m,$03
;(4) Установка статуса
    pop     h
    push    h
    ldhi    SYSPA_STATUS_0
    mvi     a,$85
    stax    d
    inx     d
    mvi     a,$00
    stax    d
;(5) Установка таблицы ассоциаций
    mvi     a,$03   ;здесь должна быть система выбора свободного сектора
    ;
    mov     b,a
    rlc
    rlc
    rlc
    rlc
    add     b
    pop     h
    push    h
    ldhi    SYSPA_TA_01
;Все виртуальные сектора кроме E и F заполнить одним значением
    mvi     c,$07
sys_cnp_cycle:
    stax    d
    inx     d
    dcr     c
    jnz     sys_cnp_cycle
;Виртуальные E и F должны совпадать с реальными
    mvi     a,$EF
    stax    d
;(6) Установка PC, SP
    pop     h
    push    h
    ldhi    SYSPA_RETADDR
    ;
    mvi     a,$03   ;здесь должна быть система выбора свободного сектора
    ;
    rlc
    rlc
    rlc
    rlc
    mov     h,a
    mvi     l,$00
    shlx
    pop     h
    push    h
    ldhi    SYSPA_SP_REG
    ori     $0F
    mov     h,a
    mvi     l,$FF
    shlx
;(7) Preparing register set
    pop     h
    push    h
    ldhi    SYSPA_STACK_HL
    lxi     h,$0000
    shlx
    inx     d
    inx     d
    shlx
    inx     d
    inx     d
    shlx
    inx     d
    inx     d
    shlx
    
    mvi     a,$CD
    sta     $3000
    mvi     a,$67
    sta     $3001
    mvi     a,$F0
    sta     $3002
    mvi     a,$C3
    sta     $3003
    mvi     a,$00
    sta     $3004
    mvi     a,$30
    sta     $3005
    
;(7) Возврат
    pop     h
    ret
