
; (10) Тест диспетчера задач (17.11.2023)
;
; Данная программа содержит
;   - Инквизитор (обработчик прерываний по вектору TRAP)
;   - Байтовое поле для двух структур аттрибутов процессов
;   - Процесс 0 - задержка 1с, затем увеличение на еденизу значения на экране
;   - Процесс 1 - бесконечный цикл
;   - Библиотеку SYStemFS, содержащую некоторые функции ОС
;   - Функции shex1, sthex1, 7-seg, MUL16, Delay_ms_6, COPCOUNT (служебные)
;
; Библиотека SYStemFS:
;   - SYS_OS_muutos - переход в режим ОС
;   - SYS_User_muutos - переход в режим пользователя
;   - SYS_Clear_Time_16 - инициализация и сброс счетчика системного времени
;   - SYS_Read_Time_16 - чтение значения системного времени в тиках
;   - SYS_TA_write - запись таблицы ассоциаций (ТА) из структуры атрибутов
;     процесса (САП).
;
; САП - структура атрибутов процесса
; ТА - таблица ассоциаций
;
; Структура атрибутов процесса - структура, набор переменных, индивидуальный
; для каждого процесса. Содержит поля для хранения ID, статуса процесса,
; адреса возврата в процесс, значения регистров после прерывания процесса,
; значения таблицы ассоциаций (ТА) процесса, а также поле для хранения имени
; процесса. Структуры аттрибутов процесса должны храниться в ОЗУ ЭВМ. Битовые
; поля во время инициализации копируются в ОЗУ по адресу F001H.
;
; Программа Инквизитор после срабатывания прерывания TRAP первым делом
; проверяет, что было источником прерывания. Если это был таймер, то выполняется
; переход к Диспетчеру задач. Диспетчер задач оформлен в виде части Инквизитора.
; Диспетчер задач находит указатель на САП выполнявшегося до недавнего времени
; процесса и заносит данные об адресе возврата и содержимом регистров в САП.
; Затем Диспетчер ищет следующий процесс. Находит указатель на него и загружает
; в стек новый адрес возврата и содержимое регистрового набора. Потом Диспетчер
; устанавливает новую ТА, взяв ее из САП. Далее управление передается в
; стандартный вывод (jmp SYS_User_muutos).
; Если же источником прерывания был процесс, то выполняется проверка сектора,
; в котором находится программа, инициировавшая переход в режим ОС. Если это
; НЕ сектор '0', то на экране появляется цифра '1' как код ошибки. Это случай,
; когда сам процесс пользователя инициировал переход. Если же переход был
; выполнен из сектора '0', то выполняется стандартный алгоритм обработки
; системной функции. Под системной функцией подразумевается функция, вызываемая
; пользователем, однако выполняемая в режиме ОС. Алгоритм этот включает в себя
; сложную перестановку стека.
; Во время запуска системы подпрограмма инициализации в конце своей работы
; выполняет безусловный переход на вектор TRAP-main. Перед переходом в стек
; заносится адрес возврата, соответствующий Процессу-0. Чтобы Инквизитор не
; подумал, что процесс пользователя запросил root-права самостоятельно, была
; была внедрена система 'Start pass'. Подпрограммой инициализации переменной
; SYSCELL_STARTPASS (byte) присваивается значение 01H. В Инквизиторе при
; переходе к убийце процессов если SYSCELL_STARTPASS равен 01H, выполняется
; безусловный переход в стандарный выход (jmp SYS_User_muutos). При этом
; переменной SYSCELL_STARTPASS присваивается значение 00H. 
;
; Оба процесса (Процесс-0 и Процесс-1) расположены по памяти в секторе '1'.
; Однако таблица ассоциаций для Процесса-0 выполнена таким образом, что
; Процесс-0 может выполняться по адресам сектора '2', при этом в режиме
; пользователя виртуальный сектор '2' будет преобразовываться в реальный '1'.
; Если заметить, в битовом поле САП для Процесса-0 адрес возврата указан как
; 2000H.
; Процесс-1 представляет из себя бесконечный цикл, в котором значение 11H
; записывается в ячейку памяти F004H (байт SYSPA_TA_01 САП Процесса-0). Данное
; изменение ТА запрещает доступ Процесса-0 к сектору '0'. Если бы значение
; записывалось, это немедленно привело бы к поломке Процеса-0 в третьем кванте
; времени (0.2с с момента начала работы). Однако этого не происходит. Этот
; факт доказывает, что сектор 'F' в режиме пользователя аппаратно защищен от
; записи.
; Однако замечено, что в турборежиме на частоте 6МГц система защиты сектора 'F'
; от записи в режиме пользователя не работает и плата зависает, ничего не
; печатая на экран. При этом если не пытаться записывать информацию в важные
; ячейки сектора 'F' в турборежиме, плата работает корректно. Проблему
; необходимо исследовать.
; Процесс-0 представляет из себя задержку в 1с, а затем инкрементирование
; переменной 8010Н, значение которой затем выводится на экран с помощью
; системной функции Function. По алгоритму значение на экране должно изменяться
; примерно каждую 1 секунду. Однако на деле оно меняется раз в 2 секунды.
; Диспетчер задач запускает процессы 0 и 1 по очереди, выделяя для них равные
; кванты времени (0.1с). То, что примерно половина машинного времени уходит на
; выполение Процесса-1 есть причина, почему цифры на экране меняются медленнее,
; чем должны. Данное наблюдение доказывает правильность работы Диспетчера задач.



;Системный порт
.def SYSPORT_A =            $00
.def SYSPORT_B =            $02
.def SYSPORT_C =            $01
.def SYSPORT_INI =          $03
;Таймер
.def TIMER_COUNTER_0 =      $08
.def TIMER_COUNTER_1 =      $09
.def TIMER_COUNTER_2 =      $0A
.def TIMER_MODEREG =        $0B
;Дисплей
.def DISP_PORT =            $18

;Сигналы управления системного порта (на вывод)
.def SYS_TURBO_BITMASK =    $01     ;1-переход в турборежим тактирования
.def SYS_WB_BITMASK =       $02     ;1-запись ассоциаций в СВА, 0-функция отключена
.def SYS_WB_BITMASK_INV =   $FD
.def SYS_CLKE_BITMASK =     $04     ;1-разрешение работы таймера 2
.def SYS_CLKE_BITMASK_INV = $FB
.def SYS_SY0_BITMASK =      $01
.def SYS_SY1_BITMASK =      $08
.def SYS_SY2_BITMASK =      $02
.def SYS_SY3_BITMASK =      $04
.def SYS_SY4_BITMASK =      $08
.def SYS_SY5_BITMASK =      $10
.def SYS_SY6_BITMASK =      $20
.def SYS_MS0_BITMASK =      $40
.def SYS_MS1_BITMASK =      $80
.def SYS_PT0_BITMASK =      $08
.def SYS_PT1_BITMASK =      $10
.def SYS_PT2_BITMASK =      $20
.def SYS_AU0_BITMASK =      $40
.def SYS_AU1_BITMASK =      $80
.def SYS_PS15_BITMASK =     $01
.def SYS_PS16_BITMASK =     $02
.def SYS_PS17_BITMASK =     $04
;Биты на ввод
.def SYS_REQ_BITMASK =      $10
.def SYS_Priority_BITMASK = $20
.def SYS_CONF_BITMASK =     $40


;--<System Process Attributes>--------------------------------------------------
.def SYSPA_ID =         $00
.def SYSPA_STATUS =     $01
.def SYSPA_STATUS2 =    $02
;Table of Assotiations
.def SYSPA_TA_01 =      $03
.def SYSPA_TA_23 =      $04
.def SYSPA_TA_45 =      $05
.def SYSPA_TA_67 =      $06
.def SYSPA_TA_89 =      $07
.def SYSPA_TA_AB =      $08
.def SYSPA_TA_CD =      $09
.def SYSPA_TA_EF =      $0A
;Contains of stack
.def SYSPA_STACK_HL =   $0B
.def SYSPA_STACK_DE =   $0D
.def SYSPA_STACK_BC =   $0F
.def SYSPA_STACK_PSW =  $11
;Return address
.def SYSPA_RETADDR =    $13
.def SYSPA_L_RETADDR =  $13
.def SYSPA_H_RETADDR =  $14
;Name
.def SYSPA_NAME =       $15
.def SYSPA_NAME_0 =     $15
.def SYSPA_NAME_1 =     $16
.def SYSPA_NAME_2 =     $17
.def SYSPA_NAME_3 =     $18
.def SYSPA_NAME_4 =     $19
.def SYSPA_NAME_5 =     $1A
.def SYSPA_NAME_6 =     $1B
.def SYSPA_NAME_7 =     $1C


.def SAP_LEN =                  $1D ;29
.def num_proc =                 $02
.def temp_proc_cell =           $FFFF
.def SAP_START_ADDR =           $F001
;Указатель на структуру атрибутов процесса, который следует отложить (archive)
.def SYSCELL_PROCTOARCH = $FFFD
;Указатель на структуру атрибутов процесса, который следует запустить (run)
.def SYSCELL_PROCTORUN = $FFFB
;Переменная, открючающая начальное убийство процесса
.def SYSCELL_STARTPASS = $FFFA


Start:
; Устанавливаем указатель стека
    lxi sp,EFF0H
; Инициализируем порт
    mvi a,88H
    out 03H
    jmp m1


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

;(1a) Источник прерывания - таймер
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


    jmp     trap_source_end
    
    

;(1b) Источник прерывания - процесс    
trap_source_proc:
;Получение значения адреса старшего байта адреса процесса пользователя,
;откуда был выполнен переход в режим ОС
    lxi     h,$000B     ;смещение 11
    dad     sp          ;(HL)=(SP)+11
    mov     a,m         ;(A)-старший байт адреса процесса пользователя
    ani     $F0
    ;cpi     $F0         ;проверка на сектор 'F'
    cpi     $00         ;проверка на сектор '0'
    ;cpi     $20         ;проверка на сектор '2'
    jz      trap_stack_form     ;переход к выполнению системной функции

;(1ba) Убить процесс
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
    call    7-seg
    cma
    out     DISP_PORT
    jmp     trap_source_end     ;переход к стандартному возврату
    
;(1bb) Переход к исполнению системной функции
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

;(2) Стандартный возврат
trap_source_end:
    jmp     SYS_User_muutos
;-------------------------------------------------------------------------------

.include    /home/victor/Desktop/Laulaja_tests/SYStemFS.asm

;-------------------------------------------------------------------------------
;---<System_process_attributes>-------------------------------------------------
;SAP_START_ADDR:
SAP_START_ADDR_ROM:
;--<1st process>----------------------------------------------------------------
.db $00     ;SYSPA_ID =         $00
.db $00     ;SYSPA_STATUS =     $01
.db $00     ;SYSPA_STATUS2 =    $02
;Table of Assotiations
.db $01     ;SYSPA_TA_01 =      $03
.db $13     ;SYSPA_TA_23 =      $04
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
.dw $2000   ;SYSPA_RETADDR =    $13
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
.dw user_2_cycle   ;SYSPA_RETADDR =    $13
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

;---<Подпрограмма инициализации>------------------------------------------------
m1:
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
    ;lxi     h,user_cykle
    lxi     h,$2000
    push    h
;Переход к TRAP
    jmp     TRAP-main


;---<Некоторые служебные функции>-----------------------------------------------
7-seg:
    call    sthex1
    lxi     b,STR-7seg
    add     c
    mov     c,a
    ldax    b
    ret
STR-7seg:
    .db     3FH
    .db     06H
    .db     5BH
    .db     4FH
    .db     66H
    .db     6DH
    .db     7DH
    .db     07H
    .db     7FH
    .db     6FH
    .db     77H
    .db     7CH
    .db     58H
    .db     5EH
    .db     79H
    .db     71H

sthex1:
    sui     30H
    cpi     0AH
    rm
    sui     07H
    ret
shex1:
    adi     30H
    cpi     3AH
    rm
    adi     07H
    ret

; Функция MUL16 - умножение 16р чисел
; Ввод: HL (множимое)
;       DE (множитель)
; Вывод: HL (младшее слово произведения)
; Используемые регистры: все
; Используемая память: нет
; Длина: 26 байт
; Время выполнения: 1001..1065 тактов
MUL16:
    mov     c,l
    mov     b,h
    lxi     h,0000H
    mvi     a,0FH
mul16_1:
    push    psw
    ora     d
    jp      mul16_2
    dad     b
mul16_2:
    dad     h
    xchg
    dad     h
    xchg
    pop     psw
    dcr     a
    jnz     mul16_1
    ora     d
    rp
    dad     b
    ret    

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



;---<Системная функция, выполняется в режиме ОС>--------------------------------

Function:
    call    SYS_OS_muutos
    lda     $8010
    ani     $0F
    call    shex1
    call    7-seg
    cma
    out     DISP_PORT
    ret


;---<Процесс 0>-----------------------------------------------------------------
;Сектор '2'
; Внимание, все переходы следующих 2 функций должны быть заменены с '1' сектора
; на '2'. Это очень важно
    .org $1000
user_cykle:
;Программа для пользователя    
    lda     8010H
    inr     a
    sta     8010H
    ;lxi     h,$03E8 ;6MHz
    lxi     h,$01F4 ;3MHz
    call    Delay_ms_6
    call    Function
    jmp     user_cykle

;---<Процесс 1>-----------------------------------------------------------------
user_2_cycle:
    mvi     a,$11
    sta     $F004
    jmp     user_2_cycle
