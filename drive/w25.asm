; (E) Barsotion KY 12.07.2023 (тест Erase & Write 04.12.2023
; Драйвер ЭСППЗУ типов W25Q32, W25Q64, W25Q128
;
; W25_SET_BASE_ADDRESS (ADDR) ------------ Установка базового адреса переменных
; W25_SET_SS_BIT (byte) ------------------ Установка бита SS ('выбор чипа')
; W25_SS_DOWN () ------------------------- Сбросить SS в лог.0
; W25_SS_UP () --------------------------- Установить SS в лог.1
; (id1,id2)W25_READ_ID () ---------------- Чтение Manufacturer_ID и Device_ID
; W25_SECTOR_WRITE (sect_addr,buf_addr) -- Запись 4кБ-сектора
; W25_SECTOR_READ (sect_addr,buf_addr) --- Чтение 4кБ-сектора
; W25_SECTOR_ERASE (sect_addr) ----------- Стирание 4кБ-сектора
;

;Входные константы
;.def DISK_SS_PORT =                 SSPI_PORT
;Входные переменные
;.def W25_BASE_ADDRESS_CELL =        $8100 ;базовый адрес

.def W25_Write_Enable =             $06
.def W25_Volatile_SR_Write_Enable = $50
.def W25_Write_Disable =            $04
.def W25_Read_SR1 =                 $05
.def W25_Write_SR1 =                $01
.def W25_Read_SR2 =                 $35
.def W25_Write_SR2 =                $31
.def W25_Read_SR3 =                 $15
.def W25_Write_SR3 =                $11
.def W25_Chip_Erase =               $60
.def W25_Power_Down =               $B9
.def W25_Release_Power_Down_ID =    $AB
.def W25_Manufacturer_Device_ID =   $90
.def W25_JEDEC_ID =                 $9F
.def W25_Global_Block_Lock =        $7E
.def W25_Global_Block_Unlock =      $98
.def W25_Enter_QPI_Mode =           $38
.def W25_Enable_Reset =             $66
.def W25_Reset_Device =             $99
.def W25_Read_Unique_ID =           $4B
.def W25_Page_Program =             $02
.def W25_Quad_Page_Program =        $32
.def W25_Sector_Erase_4KB =         $20
.def W25_Sector_Erase_32KB =        $52
.def W25_Sector_Erase_64KB =        $D8
.def W25_Read_Data =                $03
.def W25_Fast_Read =                $0B
;Внутренние переменные
.def W25LIB_UI8VAR1_CELL =          $00 ;$01
.def W25LIB_UI8VAR2_CELL =          $01 ;$02
.def W25LIB_UI8VAR3_CELL =          $02 ;$03
.def W25LIB_UI16VAR_CELL =          $03 ;$04
.def W25_SS_PIN_CELL =              $05 ;$06 ;номер пина SS микросхемы


; Функция W25_SET_BASE_ADDRESS - установка базового адреса для локальных
; переменных библиотеки
; Вход: (stack+2) - базовый адрес (word)
; Выход: нет
; Используемые регистры: DE,HL
; Используемая память: W25_BASE_ADDRESS_CELL (word)
; Длина: 7 байт
; Время выполнения: 58 тактов

W25_SET_BASE_ADDRESS:
    pop     d
    pop     h
    push    d
    shld    W25_BASE_ADDRESS_CELL
    ret

; Функция W25_SET_SS_BIT - установка адреса бита SS, подключаемого к диску
; Вход: (stack+2)H - адрес бита (0-7) (byte)
; Выход: нет
; Используемые регистры: все
; Используемая память: W25_SS_PIN_CELL (byte)
; Длина: 10 байт
; Время выполнения: 78 тактов

W25_SET_SS_BIT:
    pop     d
    pop     psw
    push    d
    ; sta     W25_SS_PIN_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25_SS_PIN_CELL
    stax    d
    ret

; Функции W25_SS_DOWN и W25_SS_UP - спуск и подъем фронта сигнала SS
; Вход: (W25_SS_PIN_CELL) - номер бита SS (byte)
; Выход: нет
; Используемые регистры: AF,BC,HL
; Длина: по 12 байт
; Время выполнения: по 147 тактов

W25_SS_DOWN:
    in      DISK_SS_PORT
    mov     b,a
    ;lda     W25_SS_PIN_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25_SS_PIN_CELL
    ldax    d
;    call    BITCLR
    cma
    ana     b
    out     DISK_SS_PORT
    ret
W25_SS_UP:
    in      DISK_SS_PORT
    mov     b,a
    ;lda     W25_SS_PIN_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25_SS_PIN_CELL
    ldax    d
;    call    BITSET
    ora     b
    out     DISK_SS_PORT
    ret

; Функция W25_READ_ID - чтение ID микросхемы и производителя
; Вход: нет
; Выход: (stack+2)H - Manufacturer ID
;        (stack+2)L - Device ID
; Используемые регистры: все
; Изменяемая память: нет
; Используемые функции:
;  - W25_SS_DOWN
;  - W25_SS_UP
;  - SPI_EX
; Длина: -
; Время выполнения: -

W25_READ_ID:
    call    W25_SS_DOWN
    mvi     a,W25_Manufacturer_Device_ID
    call    SPI_EX
    xra     a
    call    SPI_EX
    xra     a
    call    SPI_EX
    xra     a
    call    SPI_EX
    mvi     a,$FF
    call    SPI_EX
    mov     d,a
    mvi     a,$FF
    call    SPI_EX
    mov     e,a
    push    d
    call    W25_SS_UP
    pop     d
    pop     h
    push    d
    pchl

; Функция W25_SECTOR_WRITE - запись 4кБ-сектора в память диска
; Вход: (stack+4) - адрес сектора диска (0-4095)
;       (stack+2) - начальный адрес 4кБ буфера в ОЗУ ЭВМ
; Выход: нет
; Используемые регистры: все
; Изменяемая память:
;  - W25LIB_UI8VAR1_CELL (byte)
;  - W25LIB_UI8VAR2_CELL (byte)
;  - W25LIB_UI8VAR3_CELL (byte)
;  - W25LIB_UI16VAR_CELL (word)
; Используемые функции:
;  - W25_SS_DOWN
;  - W25_SS_UP
;  - SPI_EX
; Длина: -
; Время выполнения: -

W25_SECTOR_WRITE:
;Операции со стеком
    pop     b  ;адрес возврата
    pop     d  ;stack+2
    pop     h  ;stack+4
    push    b
    push    h
    push    d
;Подготовка адреса буфера
    lhld W25_BASE_ADDRESS_CELL  ;HL <- base_addr
    ldhi W25LIB_UI16VAR_CELL    ;DE <- base_addr + bias_addr
    pop     h
    shlx                        ;M(DE) <- HL
;Подготовка адреса сектора
    ; DE - sector address
    pop     d
    mvi     a,$0F  ;Очистить старшие 4 бита адреса сектора
    ana     d      ;очистка CY
    mov     d,a
    rdel       ;сдвиг DE на 4 влево
    rdel
    rdel
    rdel       ;в DE готовый адрес сектора
    mov     a,d
    mov     c,e
    ; sta     W25LIB_UI8VAR1_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR1_CELL 
    stax    d
    mov     a,c
    ; sta     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    stax    d
    xra     a
    ; sta     W25LIB_UI8VAR3_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR3_CELL 
    stax    d
sector_write_cycle2:
;Разрешение записи (команда Page program сбрасывает бит разрешения записи
;после экзекуции)
    call    W25_SS_DOWN
    mvi     a,W25_Write_Enable
    call    SPI_EX
    call    W25_SS_UP
;Отправка команды записи станицы сектора
    call    W25_SS_DOWN
    mvi     a,W25_Page_Program
    call    SPI_EX
    ; lda     W25LIB_UI8VAR1_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR1_CELL 
    ldax    d
    call    SPI_EX
    ; lda     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    ldax    d
    call    SPI_EX
    ; lda     W25LIB_UI8VAR3_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR3_CELL 
    ldax    d
    call    SPI_EX
;Отправка 256-байтного пакета
    ; HL - адрес буфера
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI16VAR_CELL
    lhlx
    mvi     d,$00
sector_write_cycle1:
    mov     a,m
    call    SPI_EX
    inx     h
    dcr     d
    jnz     sector_write_cycle1
;сохранить адрес буфера в локальную память
    ; shld    W25LIB_UI16VAR_CELL
    push    h
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI16VAR_CELL
    pop     h
    shlx
;окончание команды записи
    call    W25_SS_UP
;Waiting for the 'ready' answer 
sector_write_wait:
    call    W25_SS_DOWN
    mvi     a,W25_Read_SR1
    call    SPI_EX
    mvi     a,$FF
    call    SPI_EX     ;A <- StatusReg1
    push    psw
    call    W25_SS_UP
    pop     psw
    ani     $01         ;Mask of the BUSY bit
    ;Если равен 0, то на выход
    jnz     sector_write_wait
;Добавление $100 к адресу сектора
    ; lda     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    ldax    d
    inr     a
    ; sta     W25LIB_UI8VAR2_CELL
    stax    d
    ani     $0F
    jnz     sector_write_cycle2
;Disable writing
    call    W25_SS_DOWN
    mvi     a,W25_Write_Disable
    call    SPI_EX
    call    W25_SS_UP
    ret

; Функция W25_SECTOR_READ - чтение 4кБ-кластера с диска
; Вход: (stack+4) - адрес сектора диска (0-4095)
;       (stack+2) - начальный адрес 4кБ буфера в ОЗУ ЭВМ
; Выход: нет
; Используемые регистры: все
; Изменяемая память:
;  - W25LIB_UI8VAR1_CELL (byte)
;  - W25LIB_UI8VAR2_CELL (byte)
;  - W25LIB_UI8VAR3_CELL (byte)
;  - W25LIB_UI16VAR_CELL (word)
; Используемые функции:
;  - W25_SS_DOWN
;  - W25_SS_UP
;  - SPI_EX
; Длина: -
; Время выполнения: -

W25_SECTOR_READ:
;Операции со стеком
    pop     b  ;адрес возврата
    pop     d  ;stack+2
    pop     h  ;stack+4
    push    b
    push    h
    push    d
;Подготовка адреса буфера
    lhld    W25_BASE_ADDRESS_CELL  ;HL <- base_addr
    ldhi    W25LIB_UI16VAR_CELL    ;DE <- base_addr + bias_addr
    pop     h
    shlx                        ;M(DE) <- HL
;Подготовка адреса сектора
    ; DE - sector address
    pop     d
    mvi     a,$0F  ;Очистить старшие 4 бита адреса сектора
    ana     d      ;очистка CY
    mov     d,a
    rdel       ;сдвиг DE на 4 влево
    rdel
    rdel
    rdel       ;в DE готовый адрес сектора
    mov     a,d
    mov     c,e
    ; sta     W25LIB_UI8VAR1_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR1_CELL 
    stax    d
    mov     a,c
    ; sta     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    stax    d
    xra     a
    ; sta    W25LIB_UI8VAR3_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR3_CELL 
    stax    d
sector_read_cycle2:
;Отправка команды чтения сектора
    call    W25_SS_DOWN
    mvi     a,W25_Read_Data
    call    SPI_EX
    ;lda     W25LIB_UI8VAR1_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR1_CELL 
    ldax    d
    call    SPI_EX
    ;lda     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    ldax    d
    call    SPI_EX
    ;lda     W25LIB_UI8VAR3_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR3_CELL 
    ldax    d
    call    SPI_EX
;Чтение 256 байт
    lhld    W25_BASE_ADDRESS_CELL  ;HL - адрес буфера
    ldhi    W25LIB_UI16VAR_CELL
    lhlx
    mvi     d,$00
sector_read_cycle1:
    mvi     a,$FF
    call    SPI_EX
    mov     m,a
    inx     h
    dcr     d
    jnz     sector_read_cycle1
;сохранить адрес буфера в локальную память
    ; shld W25LIB_UI16VAR_CELL
    push    h
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI16VAR_CELL
    pop     h
    shlx
;окончание команды записи
    call    W25_SS_UP
;Добавление $100 к адресу сектора
    ;lda     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    ldax    d
    inr     a
    ;sta     W25LIB_UI8VAR2_CELL
    stax    d
    ani     $0F
    jnz     sector_write_cycle2
    ret

; Функция W25_SECTOR_ERASE - стирание 4кБ-сектора
; Вход: (stack+2) - адрес сектора диска (0-4095) (word)
; Выход: нет
; Используемые регистры: все
; Изменяемая память:
;  - W25LIB_UI8VAR1_CELL (byte)
;  - W25LIB_UI8VAR2_CELL (byte)
;  - W25LIB_UI8VAR3_CELL (byte)
; Используемые функции:
;  - W25_SS_DOWN
;  - W25_SS_UP
;  - SPI_EX
; Длина: -
; Время выполнения: -

W25_SECTOR_ERASE:
;Подготовка адреса сектора
    ;DE - sector address
    pop     h
    pop     d
    push    h
    mvi     a,$0F  ;Очистить старшие 4 бита адреса сектора
    ana     d      ;очистка CY
    mov     d,a
    rdel       ;сдвиг DE на 4 влево
    rdel
    rdel
    rdel       ;в DE готовый адрес сектора
    mov     a,d
    mov     c,e
    ;sta     W25LIB_UI8VAR1_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR1_CELL 
    stax    d
    mov     a,c
    ;sta     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    stax    d
    xra     a
    ;sta     W25LIB_UI8VAR3_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR3_CELL 
    stax    d    
;Enable writing
    call    W25_SS_DOWN
    mvi     a,W25_Write_Enable
    call    SPI_EX
    call    W25_SS_UP
;Sending the command
    call    W25_SS_DOWN
    mvi     a,W25_Sector_Erase_4KB
    call    SPI_EX
    ;lda     W25LIB_UI8VAR1_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR1_CELL 
    ldax    d
    call    SPI_EX
    ;lda     W25LIB_UI8VAR2_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR2_CELL 
    ldax    d
    call    SPI_EX
    ;lda     W25LIB_UI8VAR3_CELL
    lhld    W25_BASE_ADDRESS_CELL
    ldhi    W25LIB_UI8VAR3_CELL 
    ldax    d
    call    SPI_EX
    call    W25_SS_UP
;Waiting for the 'ready' answer
sector_erase_cycle:
    call    W25_SS_DOWN
    mvi     a,W25_Read_SR1
    call    SPI_EX
    mvi     a,$FF
    call    SPI_EX     ;A <- StatusReg1
    push    psw
    call    W25_SS_UP
    pop     psw
    ani     $01         ;Mask of the BUSY bit
    ;Если равен 0, то на выход
    jnz     sector_erase_cycle
;Disable writing
    call    W25_SS_DOWN
    mvi     a,W25_Write_Disable
    call    SPI_EX
    call    W25_SS_UP
    ret
