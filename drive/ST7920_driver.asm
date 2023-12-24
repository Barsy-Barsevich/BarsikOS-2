; (E) Barsotion
; Драйвер графического дисплея 128х64 на контроллере ST7920

; LCD_COMM_OUT -------- Отправка команды на lcd-дисплей
; LCD_DATA_OUT -------- Отправка байта данных на lcd-дисплей
; ST7920_INI ---------- Инициализация дисплея на ST7920 в граф. режиме
; ST7920_MAS ---------- Перенос массива 1кБ в видеопамять дисплея
; ST7920_PRINT_BUF ---- Перенос содержимого буфера в видеопамять дисплея
; ST7920_BUF_CLR ------ Очистка буфера

.def PORT_DISPLAY_A =       DISP_A_PORT
.def PORT_DISPLAY_B =       DISP_B_PORT
;.def DISPLAY_BUFFER_ADDR =  start_buf_addr


; (E) Barsotion KY
; Функция MacroDelay (добавлена для совместимости с ПО BarsikOS1.1)
; Используется для организации программных задержек.
; Время задержки рассчитывается по формуле: t = (20*A+25)/fтакт мкс
; Ввод: А
; Вывод: нет
; Используемые регистры: АF
; Используемая память: нет
; Длина: 5 байт
; Время выполнения: 20*A+25 тактов
MacroDelay:
    ; в А - операнд
    sui 01H
    jnz MacroDelay
    ret

; Функция LCD_COMM_OUT - отправка команды на lcd-дисплей
; Используется для организации общения с lcd дисплеями по 8-бит параллельной шине.
;
; Выводы портов:
; - Порт PORT_DISPLAY_A (тип 'A' ИС 8255), инициализирован на вывод.
;   Это шина данных к дисплею.
; - Порт 02Н (тип 'B' ИС 8255), инициализирован на вывод.
;   B(0) -- Enable
;   B(1) -- R/W
;   B(2) -- Data/Comm
;   остальные линии порта не изменяются.
; Ввод: A
; Вывод: нет
; Используемые регистры: АF,C
; Используемая память: нет
; Используемые функции:
;  - MacroDelay
; Длина: 26 байт
; Время выполнения: 173 такта

LCD_COMM_OUT:
    mov     c,a
    in      PORT_DISPLAY_B
    ani     F8H
    out     PORT_DISPLAY_B
    mov     a,c
    out     PORT_DISPLAY_A
    in      PORT_DISPLAY_B
    inr     a
    out     PORT_DISPLAY_B
    mvi     a,01H
    call    MacroDelay
    in      PORT_DISPLAY_B
    dcr     a
    out     PORT_DISPLAY_B
    ret


; Функция LCD_DATA_OUT - отправка байта данных на lcd-дисплей
; Используется для организации общения с lcd дисплеями по 8-бит параллельной шине.
;
; Выводы портов:
;
; - Порт PORT_DISPLAY_A (тип 'A' ИС 8255), инициализирован на вывод.
;   Это шина данных к дисплею.
; - Порт PORT_DISPLAY_B (тип 'B' ИС 8255), инициализирован на вывод.
;   B(0) -- Enable
;   B(1) -- R/W
;   B(2) -- Data/Comm
;   остальные линии порта не изменяются.
; Ввод: A
; Вывод: нет
; Используемые регистры: АF,C
; Используемая память: нет
; Используемые функции:
;  - MacroDelay
; Длина: 29 байт
; Время выполнения: 183 такта

LCD_DATA_OUT:
    mov     c,a
    in      PORT_DISPLAY_B
    ani     F8H
    adi     04H
    out     PORT_DISPLAY_B
    mov     a,c
    out     PORT_DISPLAY_A
    in      PORT_DISPLAY_B
    inr     a
    out     PORT_DISPLAY_B
    mvi     a,01H
    call    MacroDelay
    in      PORT_DISPLAY_B
    ani     F8H
    out     PORT_DISPLAY_B
    ret


; Функция ST7920_INI - инициализация дисплея на ST7920 в граф. режиме
; Ввод: нет
; Вывод: нет
; Используемые регистры: АF,C
; Используемая память: нет
; Используемые функции:
;  - LCD_COMM_OUT
;  - LCD_DATA_OUT
;  - MacroDelay
; Длина: 29 байт
; Время выполнения: 11696 тактов

ST7920_INI:
    call    SYS_OS_muutos
    lxi     h,$C800
    shld    DISPLAY_BUFFER_ADDR
    mvi     a,30H
    call    LCD_COMM_OUT
    mvi     a,0CH
    call    LCD_COMM_OUT
    mvi     a,30H
    call    LCD_COMM_OUT
    mvi     a,01H
    call    LCD_COMM_OUT
    mvi     a,FFH
    call    MacroDelay
    mvi     a,FFH
    call    MacroDelay
    mvi     a,34H
    call    LCD_COMM_OUT
    mvi     a,02H
    call    LCD_COMM_OUT
    mvi     a,36H
    call    LCD_COMM_OUT
    ret


; Функция ST7920_MAS - перенос массива 1кБ в видеопамять дисплея
; Ввод: stack+2 - начальный ардес массива в памяти
; Вывод: нет
; Используемые регистры: АF,C,DE,HL
; Читаемая память:
; Используемая память:
;  - disp_addr_x (byte)
;  - disp_addr_y (byte)
; Используемые функции:
;  - LCD_COMM_OUT
;  - LCD_DATA_OUT
;  - MacroDelay
; Длина: -
; Время выполнения: -

ST7920_MAS:
;работа со стеком
    pop     h
    xthl
    mvi     a,$02           ;счетчик циклов
    push    psw
;установка начальных адресов X и Y
    mvi     d,$80           ;D <- X
    mov     e,d             ;E <- Y
;Здесь: сначала печатаются $20 строк с Xнач.=$80, Yнач.=$80, Y инкрементируется
;с каждой новой строки. Потом: $20 строк с Xнач.=$88, Yнач.=$80
gr_mas_2:
    mov     a,e             ;отправка адреса Y
    call    LCD_COMM_OUT
    mov     a,d             ;отправка адреса X
    call    LCD_COMM_OUT
    mvi     b,10H           ;счетчик в B
gr_mas_1:                   ;печатаем на экран 16 байт из памяти
    mov     a,m             ; 
    call    LCD_DATA_OUT    ;
    inx     h
    dcr     b
    jnz     gr_mas_1        ;Зацикливание 1
    inr     e               ;Инкремент адреса Y
    mov     a,e             ;Смотрим, не равен ли Y 80H + 20H
    cpi     A0H             ;
    jnz     gr_mas_2        ;Зацикливание 2
    pop     psw
    dcr     a
    rz
    push    psw
    mvi     e,$80           ;Y <- $80
    mvi     d,$88           ;X <- $88
    jmp     gr_mas_2


; Функция ST7920_PRINT_BUF - перенос содержимого буфера в видеопамять дисплея
; Ввод: (DISPLAY_BUFFER_ADDR) (word) - адрес начала буфера в памяти
; Вывод: нет
; Используемые регистры: АF,C,DE,HL
; Читаемая память:
;  - start_buf_addr (word)
; Используемая память: нет
; Используемые функции:
;  - lcdCommOut
;  - lcdDataOut
;  - MacroDelay
;  - GR_MAS
; Длина: 
; Время выполнения:

ST7920_PRINT_BUF:
    call    SYS_OS_muutos
    lhld    DISPLAY_BUFFER_ADDR
    push    h
    call    ST7920_MAS
    ret


; Функция ST7920_BUF_CLR - очистка буфера
; Ввод:  (DISPLAY_BUFFER_ADDR) - Адрес начала буфера в памяти
; Вывод: нет
; Используемые регистры: AF,С,DE,HL
; Читаемая память:
;  - start_buf_addr
; Используемая память: нет
; Используемые функции:
;  - MFILL
; Длина: 12 байт
; Время выполнения: 37960 тактов

ST7920_BUF_CLR:
    call    SYS_OS_muutos
    lxi     d,0400H
    lhld    DISPLAY_BUFFER_ADDR
    xra     a
    call    MFILL
    ret
