;SYStemFS - a set of OS functions


; SYS_OS_muutos
; SYS_User_muutos
; SYS_Read_Time_Ms
; SYS_TA_write
; SYS_QuantTime_Set
; SYS_UsrAddr_to_OSAddr
; SYS_PIC_INIT


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


;Подстава лютейшая, как же долго я ее искал
;Эта функция должна быть в секторе F
;; SYStemFS
;; Функция SYS_User_muutos - переход в режим пользователя
;; Ввод: нет
;; Вывод: нет
;; Используемые регистры: все
;; Используемые порты: таймер номер 2
;; Оценка: длина - 23 байта, время - 123 такта
;SYS_User_muutos:
;;Настройка таймера
;    mvi     a,B0H
;    out     TIMER_MODEREG
;    lhld    SYSCELL_QUANT_TIME
;    mov     a,l
;    out     TIMER_COUNTER_2
;    mov     a,h
;    out     TIMER_COUNTER_2
;; Включаем режим пользователя
;    mvi     a,40H
;    sim
;    mvi     a,C0H
;    sim
;    pop     h
;    pop     d
;    pop     b
;    pop     psw
;    ret


; SYStemFS
; Функция SYS_Read_Time_Ms - чтение системного времени (в микросекундах)
; Ввод: нет
; Вывод: (HL) - время в микросекундах
; Используемые регистры: AF,HL
; Оценка: длина - байт, время -  тактов
SYS_Read_Time_Ms:
;Send code to latch counting
    mvi     a,$00
    out     TIMER_MODEREG
    in      TIMER_COUNTER_0
    cma
    mov     l,a
    in      TIMER_COUNTER_0
    cma
    mov     h,a
    ret


; SYStemFS
; Функция SYS_TA_write - запись таблицы ассоциаций из аттрибутов процесса
; Ввод: (HL)-указатель на структуру аттрибутов процесса
; Вывод: нет
; Используемые регистры: все
; Оценка: длина - , время - 
SYS_TA_write:
    push    h
;Сохранение значений ячеек по адресам X000H
    lxi     h,$0000
    lxi     d,SYSCELL_WB_MEMORY_SAVE
    mvi     c,$10
sys_ta_write_1:
    mov     a,m
    stax    d
    inx     d
    mvi     a,$10
    add     h
    mov     h,a
    dcr     c
    jnz     sys_ta_write_1
    pop     h
;Запись в банк
    in      SYSPORT_C
    ori     SYS_WB_BITMASK
    ori     SYS_CLKE_BITMASK
    out     SYSPORT_C
    ldhi    SYSPA_TA_01
    mvi     c,$08
    lxi     h,$0000
sys_ta_write_cycle:
    ldax    d
    cma
    mov     b,a
    ani     $F0
    rrc
    rrc
    rrc
    rrc
    mov     m,a
    mvi     a,$10
    add     h
    mov     h,a
    mov     a,b
    ani     $0F
    mov     m,a
    mvi     a,$10
    add     h
    mov     h,a
    inx     d
    dcr     c
    jnz     sys_ta_write_cycle
;Выключение режима записи в банк
    in      SYSPORT_C
    ani     SYS_WB_BITMASK_INV
    ori     SYS_CLKE_BITMASK
    out     SYSPORT_C
;Выгрузка сохраненных значений ячеек помяти по адресам X000H
    lxi     h,$0000
    lxi     d,SYSCELL_WB_MEMORY_SAVE
    mvi     c,$10
sys_ta_write_2:
    ldax    d
    mov     m,a
    inx     d
    mvi     a,$10
    add     h
    mov     h,a
    dcr     c
    jnz     sys_ta_write_2
    ret


; SYStemFS
; Функция SYS_QuantTime_Set - установка величины кванта времени
; Ввод: (HL)-указатель на структуру аттрибутов процесса
; Вывод: нет
; Используемые регистры: все
; Оценка: длина - , время - 
SYS_QuantTime_Set:
    ldhi    SYSPA_STATUS_0
    ldax    d
    ani     $07
    add     a
    mov     e,a
    mvi     d,$00
    lxi     h,sys_quanttime_set_1
    dad     d
    xchg
    lhlx
    shld    SYSCELL_QUANT_TIME
    ret
sys_quanttime_set_1:
    .dw     $0BB8   ;3000  Приоритет 0 (низший)
    .dw     $1388   ;5000  Приоритет 1 (фоновый)
    .dw     $1D4C   ;7500  Приоритет 2 (пользовательский)
    .dw     $2710   ;10000 Приоритет 3 (пользовательский)
    .dw     $4E20   ;20000 Приоритет 4 (пользовательский)
    .dw     $7530   ;30000 Приоритет 5 (пользовательский)
    .dw     $9C40   ;40000 Приоритет 6 (системный)
    .dw     $EA60   ;60000 Приоритет 7 (высший)
    

; SYStemFS
; SYS_UsrAddr_to_OSAddr - преобразование абсолютного адреса режима ОС в
; адрес режима пользователя
; Ввод:  HL - указатель на САП
;        DE - адрес для преобразования
; Вывод: DE - преобразованный адрес
; Используемые регистры: AF,B,D,HL
; Читаемая памать: поля SYSPA_TA структуры атрибутов процесса
; Оценка: длина: - , время - 
SYS_UsrAddr_to_OSAddr:
;Вычисление адреса смещения в САП для получения значения таблицы ассоциаций
;HL <- HL+DE[15:13]+SYSPA_TA_01
    mov     a,d
    ani     $E0
    rlc
    rlc
    rlc
    adi     SYSPA_TA_01
    add     l
    mov     l,a
    mvi     a,$00
    adc     h
    mov     h,a
;Если DE[12]==0, то берем старшую тетраду, иначе - младшую
    mov     a,d
    ani     $10
    mov     a,m
    jz      sys_usraddr_to_osaddr_1
    rlc
    rlc
    rlc
    rlc
sys_usraddr_to_osaddr_1:
    ani     $F0
    mov     b,a
    mov     a,d
    ani     $0F
    add     b
    ret


; SYStemFS
; SYS_PIC_INIT - Инициализация контроллера прерываний КР1810ВН59А
; Ввод: нет
; Вывод: нет
; Используемые регистры: AF,HL
; Используемые порты: PIC_REG_A0,PIC_REG_A1
; Используемая память: нет
; Использование функций:
;  - COPCOUNT
; Оценка: длина - , время - 
SYS_PIC_INIT:
    lxi     h,PIC_INT_STARTADDR
;(1) Отправка команды СКИ1и или СКИ1к (D3=0 - по фронту, иначе по уровню)
;ПКП в системе единственный, смещение адресов векторов 4.
;|A7|A6|A5|1|0|1|1|1|
    mov     a,l
    ani     $E0
    ori     PIC_ICW1
    out     PIC_REG_A0
;(2) Отправка команды СКИ2
;|A15|A14|A13|A12|A11|A10|A9|A8|
    mov     a,h
    out     PIC_REG_A1
;Команды СКИ3 и СКИ4 пропустить
;(3) Отправка команды СКО1
    mvi     a,PIC_DEFAULT_INTMASK
    out     PIC_REG_A1
;(4) Отправка команды СКО2д
    mvi     a,$80
    out     PIC_REG_A0
;(5) Загрузка таблицы векторов прерываний
    lxi     b,$0032
    lxi     d,SYS_Interrupt_Table_Default
    lxi     h,PIC_INT_STARTADDR
    call    COPCOUNT
;Возврат
    ret

SYS_Interrupt_Table_Default:
    .db     $C3
    .dw     INT_VECT_0
    .db     $00
    .db     $C3
    .dw     INT_VECT_1
    .db     $00
    .db     $C3
    .dw     INT_VECT_2
    .db     $00
    .db     $C3
    .dw     INT_VECT_3
    .db     $00
    .db     $C3
    .dw     INT_VECT_4
    .db     $00
    .db     $C3
    .dw     INT_VECT_5
    .db     $00
    .db     $C3
    .dw     INT_VECT_6
    .db     $00
    .db     $C3
    .dw     INT_VECT_7
    .db     $00
