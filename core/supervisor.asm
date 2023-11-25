; Supervisor - главное тело 0000H

.include /home/victor/Desktop/BarsikOS-2/core/systemdef.def
.include /home/victor/Desktop/BarsikOS-2/core/smm.def
.include /home/victor/Desktop/BarsikOS-2/core/libraries.h

;Вектор 0 - фатальная ситуация сброса
    .org    $0000


;Вектор 21H - Горячий старт ОС
    .org    $0021
    jmp     Hot_Start_OS


;Вектор 24Н - Инквизитор
;----<Инквизитор>---------------------------------------------------------------
    .org 0024H
TRAP-main:
    push    psw
    push    b
    push    d
    push    h
;(1) Определяем, кто был источником прерывания
    rim             ;Чтение маски прерываний
    mov     b,a
;Сбрасываем RST7.5
    mvi     a,$10
    sim
    mov     a,b
    ani     $40     ;Выделяем RST7.5
    jz      trap_source_proc
;--<(1a) Источник прерывания - таймер>------------------------------------------
trap_source_timer:
;---<Диспетчер задач>-----------------------------------------------------------
;Нахождение указателя на САП, который следует отложить
    lda     temp_proc_cell
    mov     e,a
    mvi     d,$00
    lxi     h,SAP_LEN
    call    MUL16
    lxi     d,SAP_START_ADDR
    dad     d
    shld    SYSCELL_PROCTOARCH
;Смена процесса
    lda     temp_proc_cell
    inr     a
    sta     temp_proc_cell
    sui     num_proc
    jnz     arch_run_1
    sta     temp_proc_cell
arch_run_1:
;Нахождение указателя на САП, который следует запустить
    lda     temp_proc_cell
    mov     e,a
    mvi     d,$00
    lxi     h,SAP_LEN
    call    MUL16
    lxi     d,SAP_START_ADDR
    dad     d
    shld    SYSCELL_PROCTORUN
; [HL]
; [DE]
; [BC]
; [PSW]
; [USER]
;(1) Откладываем текущий процесс
    lhld    SYSCELL_PROCTOARCH
;(HL)-указатель на структуру аттрибутов процесса
    ldhi    SYSPA_STACK_HL
    xchg
    mvi     c,$05
sys_archive_proc_1:
    pop     d   ;[HL],[DE],[BC],[PSW],[USER]
    mov     m,e
    inx     h
    mov     m,d
    inx     h
    dcr     c
    jnz     sys_archive_proc_1
;(2) Подготавливаем стек под новый процесс
    lhld    SYSCELL_PROCTORUN
;(HL)-указатель на структуру аттрибутов процесса
    ldhi    SYSPA_H_RETADDR
    xchg
    mvi     c,$05
sys_run_proc_1:
    mov     d,m
    dcx     h
    mov     e,m
    dcx     h
    push    d   ;[USER],[PSW],[BC],[DE],[HL]
    dcr     c
    jnz     sys_run_proc_1
;(3) Загружаем таблицу ассоциаций для нового процесса
    lhld    SYSCELL_PROCTORUN
    call    SYS_TA_write
;(4) Загружаем размер кванта времени для нового процесса
    lhld    SYSCELL_PROCTORUN
    call    SYS_QuantTime_Set
    ;
    jmp     trap_source_end
;---<(1b) Источник прерывания - процесс>----------------------------------------    
trap_source_proc:
;Получение значения адреса старшего байта адреса процесса пользователя,
;откуда был выполнен переход в режим ОС
    lxi     h,$000B     ;смещение 11
    dad     sp          ;(HL)=(SP)+11
    mov     a,m         ;(A)-старший байт адреса процесса пользователя
    ani     $F0
    cpi     $F0         ;проверка на сектор 'F'
    ;cpi     $00         ;проверка на сектор '0'
    jz      trap_stack_form     ;переход к выполнению системной функции
;---<(1ba) Убить процесс>-------------------------------------------------------
    ;Смотрим SYSCELL_STARTPASS (Если не равен 0, то не убиваем. Установ в 0)
    lda     SYSCELL_STARTPASS
    mov     b,a
    xra     a
    sta     SYSCELL_STARTPASS
    mov     a,b
    ora     a
    jnz     trap_source_end     ;переход к стандартному выходу
    ;печать значения 1 на экране
    mvi     a,$31
    call    ASCSEG7
    ori     $80
    cma
    out     DISP_PORT
    jmp     trap_source_end     ;переход к стандартному возврату
;---<(1bb) Переход к исполнению системной функции>------------------------------
trap_stack_form:
;Перестановка:
; [HL]          
; [DE]          [USR_MUUTOS]
; [BC]          [HL]
; [PSW]         [DE]
; [SYS_OS] ->   [BC]
; [FUN]         [PSW]
; [USER]   =    [USER]
; [DI]     =    [DI]
;Работаем:
    pop     psw     ;HL
    pop     b       ;DE
    pop     d       ;BC
    pop     h       ;PSW
    xthl            ;(HL)=[SYS_OS], (stack)=PSW
    pop     h       ;PSW
    xthl            ;(HL)=[FUN], (stack)=PSW
    push    d       ;BC
    push    b       ;DE
    push    psw     ;HL
;Загрузка указателя на функцию SYS_User_muutos
    lxi     d,SYS_User_muutos
    push    d
;Переход к системной функции
    ;(HL)-адрес возврата [FUN]
    pchl
;---<(2) Стандартный возврат>---------------------------------------------------
trap_source_end:
    jmp     SYS_User_muutos
;-------------------------------------------------------------------------------





;---<Подпрограмма "Горячий старт ОС">-------------------------------------------
Hot_Start_OS:
;CLKE и Турборежим
    mvi     a,SYS_CLKE_BITMASK
    ;mvi     a,$05   ;SYS_CLKE_BITMASK | SYS_TURBO_BITMASK
    out     SYSPORT_C
;Начальный процесс - 0
    mvi     a,$00
    sta     temp_proc_cell
;Пропуск в первый заход TRAP (вырубаем убийцу процессов)
    mvi     a,$01
    sta     SYSCELL_STARTPASS
;Копируем заголовки процессов
    lxi     b,$003A
    lxi     d,SAP_START_ADDR_ROM
    lxi     h,SAP_START_ADDR
    call    COPCOUNT
; Включаем запись в банк регистров
    lxi     h,SAP_START_ADDR
    call    SYS_TA_write
;Загружаем в стек переход к пользовательскому процессу
    lxi     h,process0
    ;lxi     h,$2000
    push    h
;Переход к TRAP
    jmp     TRAP-main
;-------------------------------------------------------------------------------



;-------------------------------------------------------------------------------
;---<System_process_attributes>-------------------------------------------------
;SAP_START_ADDR:
SAP_START_ADDR_ROM:
;--<1st process>----------------------------------------------------------------
.db $00     ;SYSPA_ID =         $00
.db $07     ;SYSPA_STATUS =     $01
.db $00     ;SYSPA_STATUS2 =    $02
;Table of Assotiations
.db $01     ;SYSPA_TA_01 =      $03
.db $23     ;SYSPA_TA_23 =      $04
.db $45     ;SYSPA_TA_45 =      $05
.db $67     ;SYSPA_TA_67 =      $06
.db $89     ;SYSPA_TA_89 =      $07
.db $AB     ;SYSPA_TA_AB =      $08
.db $CD     ;SYSPA_TA_CD =      $09
.db $EF     ;SYSPA_TA_EF =      $0A
;Contains of stack
.dw $0000   ;SYSPA_STACK_HL =   $0B
.dw $0000   ;SYSPA_STACK_DE =   $0D
.dw $0000   ;SYSPA_STACK_BC =   $0F
.dw $0000   ;SYSPA_STACK_PSW =  $11
;Return address
.dw process0   ;SYSPA_RETADDR =    $13
;Name
.db $00     ;SYSPA_NAME_0 =     $15
.db $00     ;SYSPA_NAME_1 =     $16
.db $00     ;SYSPA_NAME_2 =     $17
.db $00     ;SYSPA_NAME_3 =     $18
.db $00     ;SYSPA_NAME_4 =     $19
.db $00     ;SYSPA_NAME_5 =     $1A
.db $00     ;SYSPA_NAME_6 =     $1B
.db $00     ;SYSPA_NAME_7 =     $1C
;--<2nd process>----------------------------------------------------------------
.db $01     ;SYSPA_ID =         $00
.db $00     ;SYSPA_STATUS =     $01
.db $00     ;SYSPA_STATUS2 =    $02
;Table of Assotiations
.db $01     ;SYSPA_TA_01 =      $03
.db $23     ;SYSPA_TA_23 =      $04
.db $45     ;SYSPA_TA_45 =      $05
.db $67     ;SYSPA_TA_67 =      $06
.db $89     ;SYSPA_TA_89 =      $07
.db $AB     ;SYSPA_TA_AB =      $08
.db $CD     ;SYSPA_TA_CD =      $09
.db $EF     ;SYSPA_TA_EF =      $0A
;Contains of stack
.dw $0000   ;SYSPA_STACK_HL =   $0B
.dw $0000   ;SYSPA_STACK_DE =   $0D
.dw $0000   ;SYSPA_STACK_BC =   $0F
.dw $0000   ;SYSPA_STACK_PSW =  $11
;Return address
.dw process1   ;SYSPA_RETADDR =    $13
;Name
.db $00     ;SYSPA_NAME_0 =     $15
.db $00     ;SYSPA_NAME_1 =     $16
.db $00     ;SYSPA_NAME_2 =     $17
.db $00     ;SYSPA_NAME_3 =     $18
.db $00     ;SYSPA_NAME_4 =     $19
.db $00     ;SYSPA_NAME_5 =     $1A
.db $00     ;SYSPA_NAME_6 =     $1B
.db $00     ;SYSPA_NAME_7 =     $1C
;-------------------------------------------------------------------------------


.include    /home/victor/Desktop/BarsikOS-2/core/SYStemFS.asm

;.include /home/victor/Desktop/BarsikOS-2/lib/StandartArithmetic.asm
;.include /home/victor/Desktop/BarsikOS-2/lib/AFS3.asm


process0:
    lda     $8010
    inr     a
    sta     $8010
    call    Function
    lxi     h,$01F4
    call    Delay_ms_6
    jmp     process0

process1:
    jmp     process1
