
;Что надо помнить всеми силами:
; (SP+0) - [USR_M]
; (SP+2) - [HL]
; (SP+4) - [DE]
; (SP+6) - [BC]
; (SP+8) - [PSW]
; (SP+10) - [USER]
; (SP+12) - [DI]

; (E) Barsotion KCo
; Графическая библиотека GRLIB. Здесь только проверенные функции
;
; GR_INI () ------------------------ Инициализация библиотеки
; GR_RESOLUTION (X,Y) -------------- Установка разрешения экрана
; GR_START_BUF_ADDR (ADDR) --------- Установка начального адреса видеобуфера
; GR_BORDER (RIGHT,LEFT,UP,DOWN) --- Установка границ отображаемого
; GR_INTERSECTION_STYLE (b) -------- Установка стиля пересечений
; GR_FONT (ADDR) ------------------- Установка начального адреса таблицы шрифтов
; GR_SYM_PARAMETERS (hor,vert) ----- Установка ширины и высоты символа
; GR_GAP (GAP) --------------------- Установка расстояния между символами
; GR_DOT (X,Y) --------------------- Рисование точки
; GR_WRSYM (X,Y,SYM) --------------- Рисование буквы
; GR_STOPT (ADDR,X,Y) -------------- Рисование строки пропорционального текста
; GR_STMONO (ADDR,X,Y) ------------- Рисование строки текста-моно
; GR_LINE (X0,Y0,X1,Y1) ------------ Рисование линий
; GR_CIRCLE (X,Y,R) ---------------- Рисование окружностей
; GR_FRAME (X0,Y0,X1,Y1,R) --------- Рисование скругленных прямоугольников
;

;.include /home/victor/Desktop/GRLIB/GRLIB.def

;
; Функция GR_INI - инициализация библиотеки
; Ввод: нет
; Вывод: нет
; Используемые регистры: все
; Используемая память:
;  - number_x_pixels (word)
;  - number_y_pixels (word
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - font_const (word)
;  - hor_sym (byte)
;  - vert_sym (byte)
;  - gap_const (byte)
;  - intersection_style (byte)
; Используемые функции:
;  - GR_RESOLUTION
;  - GR_START_BUF_ADDR
;  - GR_BORDER
;  - GR_INTERSECTION_STYLE
;  - GR_FONT
;  - GR_SYM_PARAMETERS
;  - GR_GAP
;
;
; Функция GR_RESOLUTION - установка разрешения экрана
; Ввод:  stack+4 -- разрешение по x (word)
;        stack+2 -- разрешение по y (word)
; Вывод: нет
; Используемые регистры: все
; Используемая память:
;  - number_x_pixels (word)
;  - number_y_pixels (word
;  - num_x_sc_bytes (byte)
; Используемые функции: нет
;
;
; Функция GR_START_BUF_ADDR - установка начального адреса видеобуфера
; Ввод:  stack+2 -- начальный адрес видеобуфера (word)
; Вывод: нет
; Используемые регистры: DE,HL
; Используемая память:
;  - start_buf_addr (word)
; Используемые функции: нет
;
;
; Функция GR_BORDER - установка границ отображаемого
; Ввод:  stack+8 -- правая граница (int)
;        stack+6 -- левая граница (int)
;        stack+4 -- верхняя граница (int)
;        stack+2 -- нижняя граница (int)
; Вывод: нет
; Используемые регистры: DE,HL
; Используемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
; Используемые функции: нет
;
;
; Функция GR_INTERSECTION_STYLE - установка стиля пересечений
; Ввод:  stack+2(H) -- стиль пересечений (byte)
;        Если == 0: закрашивание пикселя в любом случае
;        Если [0] == 1: закрашивание, если очищен; очистка, если закрашен
;        Если [0] == 2: очистка пикселя в любом случае
; Вывод: нет
; Используемые регистры: AF,HL
; Используемая память:
;  - intersection_style (byte)
; Используемые функции: нет
;
;
; Функция GR_FONT - установка таблицы шрифтов
; Ввод:  stack+2 -- адрес таблицы шрифтов (word)
; Вывод: нет
; Используемые регистры: DE,HL
; Используемая память:
;  - font_const (word)
; Используемые функции: нет
;
;
; Функция GR_SYM_PARAMETERS - установка параметров символа
; Ввод:  stack+4(H) -- число пикселей символа по горизонтали (byte)
;        stack+2(H) -- Число пикселей символа по вертикали (byte)
; Вывод: нет
; Используемые регистры: AF,HL
; Используемая память:
;  - hor_sym (byte)
;  - vert_sym (byte)
; Используемые функции: нет
;
;
; Функция GR_GAP - установка параметров символа
; Ввод:  stack+2(H) -- расстояние между символами (byte)
; Вывод: нет
; Используемые регистры: AF,HL
; Используемая память:
;  - gap_const (byte)
; Используемые функции: нет

GR_INI_USR:
    call    SYS_OS_muutos
GR_INI_INSIDE:
    ; Установка разрешения экрана, num_x_sc_bytes
    lxi     h,$0080
    shld    number_x_pixels
    call    GR_RESOLUTION_INSIDE
    lxi     h,$0040
    shld    number_y_pixels
;Устанавливаем границы
    ;границы по умолчанию:
    lxi     h,$0080     ;правая - 128
    shld    x_sc_right  ;(int)
    lxi     h,$0000     ;левая - 0
    shld    x_sc_left   ;(int)
    lxi     h,$0000     ;верхняя - 0
    shld    y_sc_upper  ;(int)
    lxi     h,$0040     ;нижняя - 64
    shld    y_sc_lower  ;(int)
;Устанавливаем стиль пересечений
;по умолчанию -- закрашивание в любом случае
    mvi     a,$00
    sta     intersection_style
;Устанавливаем ширину и высоту символа
;по умолчанию ширина - 6; высота - 8
    mvi     a,$08
    sta     vert_sym
    mvi     a,$06
    sta     hor_sym
;Устанавливаем расстояние между символами
;по умолчанию расстояние - 1 пиксель
    mvi     a,$01
    sta     gap_const
;Шрифт по умолчанию - Standart Saluan, $1800
    lxi     h,$1800
    shld    font_const
;Адрес буфера по умолчанию -- $F800
    lxi     h,$F800
    shld    start_buf_addr
    ret


GR_RESOLUTION_USR:
    call    SYS_OS_muutos
;SP+=12
    ldsi    $0C
;Чтение n=2 переменных
    lhlx
    shld    number_y_pixels
    inx     d
    inx     d
    lhlx
    shld    number_x_pixels
GR_RESOLUTION_INSIDE:
;Установка num_x_sc_bytes
;num_x_sc_bytes = number_x_pixels//8
    lhld    number_x_pixels
    mvi     c,03H
    xra     a
gr_ini_1:
    mov     b,a
    mov     a,h
    rar
    mov     h,a
    mov     a,l
    rar
    mov     l,a
    mov     a,b
    ral
    dcr     c
    jnz     gr_ini_1
;Если остаток не равен 0, прибавляем 1
    mov     a,b
    ora     a
    jz      gr_ini_2
    inx     h
gr_ini_2:
    mov     a,l
    sta     num_x_sc_bytes
    ret


GR_START_BUF_ADDR_USR:
    call    SYS_OS_muutos
    ldsi    $0C
    lhlx
    shld    start_buf_addr
    ret


GR_BORDER_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0C
;Чтение n=4 переменных
    lhlx
    shld    y_sc_lower ;(int) ; нижняя граница
    inx     d
    inx     d
    lhlx
    shld    y_sc_upper ;(int) ; верхняя граница
    inx     d
    inx     d
    lhlx
    shld    x_sc_left  ;(int) ; левая граница
    inx     d
    inx     d
    lhlx
    shld    x_sc_right ;(int) ; правая граница
    ret


GR_ISSTYLE_USR:
    call    SYS_OS_muutos
    ldsi    $0D ;12+1, потому что в PSW A-старший
    ldax    d
    sta     intersection_style
    ret


GR_FONT_USR:
    call    SYS_OS_muutos
    ldsi    $0C
    lhlx
    shld    font_const
    ret


GR_SYM_PARAMETERS_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0D
;Чтение n=2 переменных
    ldax    d
    sta     vert_sym
    inx     d
    inx     d
    ldax    d
    sta     hor_sym
    ret


GR_GAP_USR:
    call    SYS_OS_muutos
    ldsi    $0D ;12+1, потому что в PSW A-старший
    ldax    d
    sta     gap_const
    ret



;
; Функция GR_DOT - закрашивание/очистка пикселя в видеобуфере
;
; Ввод:  stack+4 -- координата x (int)
;        stack+2 -- координата y (int)
; Вывод: fC=1 -- ошибка адресации
;        fС=0 -- успешно
;
; Используемые регистры: все
; Читаемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - intersection_style (word)
;  - x
;  - y
; Используемая память: нет
; Используемые функции:
;  - MUL16
;  - BITSET
;  - CMP16
;
; Длина: 106 байтов
; Время выполнения: ~1930 тактов
;
; Начало кода:

GR_DOT_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0C
;Чтение n=2 переменных
    lhlx
    shld    y
    inx     d
    inx     d
    lhlx  
    shld    x
GR_DOT_INSIDE:
;test x & y
    lhld    x_sc_right
    xchg    
    lhld    x
    call    CMP16
    jp      print_dot_err
    xchg
    lhld    x_sc_left
    xchg
    call    CMP16
    jm      print_dot_err
    lhld    y_sc_lower
    xchg
    lhld    y
    call    CMP16
    jp      print_dot_err
    xchg
    lhld    y_sc_upper
    xchg
    call    CMP16
    jm      print_dot_err
; Умножение y на num_x_sc_bytes. Результат в DE
; Если равно 10H, ускоренно сдвигаем. Иначе - быстрое умножение
; DE <- y
    xchg
    lda     num_x_sc_bytes
    cpi     10H
    jnz     print_dot__3
; Сдвиг на 4 разряда влево
    mvi     c,$04
print_dot__4:
    ora     a
    mov     a,e
    ral
    mov     e,a
    mov     a,d
    ral
    mov     d,a
    dcr     c
    jnz     print_dot__4
; В конец секции умножения
    jmp     print_dot__5
; Быстрое умножение
print_dot__3:
    lxi     h,$0000
    mvi     c,fastmul_rotate
    mov     b,a
print_dot__1:
; B >>
    mov     a,b
    rar
    mov     b,a
; IF 1, hl+=de
    jnc     print_dot__2
    dad     d
print_dot__2:
; DE <<
    ora     a
    mov     a,e
    ral
    mov     e,a
    mov     a,d
    ral
    mov     d,a
    dcr     c
    jnz     print_dot__1
; DE <- result
    xchg
print_dot__5:
; get x//8 & x%8
; HL <- x//8
; B <- x%8
    lhld    x
    ora     a
    mvi     b,00H
    mvi     c,03H
print_dot_cycle1:
    mov     a,h
    rar 
    mov     h,a
    mov     a,l
    rar
    mov     l,a
    mov     a,b
; ! rar
    rar
    mov     b,a
    dcr     c
    jnz     print_dot_cycle1
; a - b
    rlc
    rlc
    rlc
    mov     b,a
; DE <- (y * num_x_sc_bytes) + (x//8) + start_buf_addr
    dad d
    xchg
    lhld    start_buf_addr
    dad     d
    xchg
; BITSET (7-(x%8))
    mvi     a,07H
    sub     b
    mvi     b,00H
    call    BITSET
    xchg
    mov     b,a
    lda     intersection_style
    ora     a
    mov     a,b
; Если == 0: закрашивание пикселя в любом случае
    jz      print_dot_i_s_1
; Если == 1: закрашивание, если очищен; очистка, если закрашен
    jpo     print_dot_i_s_3
; Если == 2: очистка пикселя в любом случае
    cma
    ana     m
    jmp     print_dot_i_s_2
print_dot_i_s_3:
    xra     m
    jmp     print_dot_i_s_2
print_dot_i_s_1:
    ora     m
print_dot_i_s_2:
    mov     m,a
    ret
; addressing error
print_dot_err:
    stc
    ret


;
; Функция GR_WRSYM - отрисовка символа в видеобуфере
;
; Ввод:  Начальный адрес отрисовки (верхний левый угол символа):
;        stack+6 -- x_wrsym (int)
;        stack+4 -- y_wrsym (int)
;        stack+2(H) -- now_sym (char) -- текущий отрисовываемый символ
; Вывод: xk (int) -- правая граница символа по x +1
;        fC=1 -- ошибка адресации
;        fC=0 -- успешно
;        
; Используемые регистры: все
; Читаемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - intersection_style (word)
;  - vert_sym (byte)
;  - hor_sym (byte)
;  - font_const (word)
;  - now_sym (byte)
;  - xl (int)
;  - yl (int)
; Используемая память:
;  - vert_count (byte)
;  - hor_count (byte)
;  - xk (int)
;  - x (int)
;  - y (int)
;  - wrsym_bool_err (byte)
; Используемые функции:
;  - MUX16
;  - BITSET
;  - GR_DOT_INSIDE
;  - CMP16
;
; Длина:  байта
; Время выполнения: ?
;
; Начало кода:

GR_WRSYM_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0D ;psw, a-higher
;Чтение n=3 переменных
    ldax    d
    sta     now_sym
    inx     d
    lhlx
    shld    yl
    inx     d
    inx     d
    lhlx
    shld    xl
WRSYM_INSIDE:
; vert_count <- 0
    xra     a
    sta     vert_count
; wrsym_bool_err <- 0
    sta     wrsym_bool_err
; Copying enter var yl to local y
    lhld    yl
    shld    y
wrsym_cycle2:
; hor_count <- hor_sym
    lda     hor_sym
    sta     hor_count
; Copying enter var xl to local x
    lhld    xl
    shld    x
; get the word
; A <- string of symbol
    lda     vert_count
    mov     b,a
    mvi     h,$00
    mvi     c,$03
    lda     now_sym
    ora     a
wrsym_cycle_get_word:
    ral
    mov     l,a
    mov     a,h
    ral
    mov     h,a
    mov     a,l
    dcr     c
    jnz     wrsym_cycle_get_word
    add     b
    mov     l,a
    mvi     a,$00
    adc     h
    mov     h,a
    xchg
    lhld    font_const
    dad     d
    mov     a,m
; paint 1 string of symbol
; A - string of symbol
wrsym_cycle1:
    add     a
    push    psw
    jnc     wrsym_1
; If carry, paint a dot
; save A in stack
;    call    GR_DOT_INSIDE(x:y)
    call    GR_DOT_INSIDE
; If addressing error, go to print_dot_err
    ;jc      wrsym_err
; If x>(xk-1), save (x+1) as xk
; DE <- x
    lhld    x
    xchg
; HL <- xk-1
    lhld    xk
    dcx     h
    call    CMP16
; If S==1, then int DE > int HL
    jp      wrsym_1
; save (x+1) as xk
    xchg
    inx     h
    shld    xk
; DE - x
wrsym_1:
; x += 1
    lhld    x
    inx     h
    shld    x
; get A from stack
    pop     psw
; out condition
    lxi     h,hor_count
    dcr     m
    jnz     wrsym_cycle1
wrsym_2:
; y += 1
    lhld    y
    inx     h
    shld    y
; If vert_count == ver
lda vert_count
    mov     b,a
    inr     b
    lda     vert_sym
    cmp     b
    jz      wrsym_3
    mov     a,b
    sta     vert_count
    jmp     wrsym_cycle2
wrsym_err:
    pop     h
    mvi     a,$80
    sta     wrsym_bool_err
    jmp     wrsym_2
wrsym_3:
    lda     wrsym_bool_err
    ora     a
    rz
    stc
    ret


;
; Функция GR_STOPT - отрисовка строки пропорционального текста
;
; Ввод:  Адрес начала строки в памяти:
;        stack+6 -- gr_stopt_addr (word)
;        Начальный адрес отрисовки (верхний левый угол строки):
;        stack+4 -- x_str (int)
;        stack+2 -- y_str (int)
;        Расстрояние между символами: gap_const (byte)
;        Адрес начала таблицы шрифтов: font_const (word)
; Вывод: gr_stopt_index (byte) -- оконечный индекс строки
;        
; Используемые регистры: все
; Читаемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - intersection_style (word)
;  - vert_sym (byte)
;  - hor_sym (byte)
;  - font_const (word)
;  - x_str (int)
;  - y_str (int)
;  - gr_stopt_addr (word)
;  - gap_const (byte)
; Используемая память:
;  - vert_count (byte)
;  - hor_count (byte)
;  - now_sym (byte)
;  - xk (int)
;  - x (int)
;  - y (int)
;  - xl (int)
;  - yl (int)
;  - wrsym_bool_err (byte)
;  - gr_stopt_index (byte)
; Используемые функции:
;  - MUX16
;  - BITSET
;  - GR_DOT_INSIDE
;  - WRSYM
;  - CMP16
;
; Длина:  байта
; Время выполнения: ?
;
; Начало кода:

GR_STOPT_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0C
;Чтение n=3 переменных
    lhlx
    shld    y_str
    inx     d
    inx     d
    lhlx
    shld    x_str
    inx     d
    inx     d
    lhlx
    shld    gr_stopt_addr
GR_STOPT_INSIDE:
; xk <= xl
    lhld    x_str
    shld    xl
    shld    xk
    lhld    y_str
    shld    yl
; index <= -1
    mvi     a,$FF
    sta     gr_stopt_index
gr_stopt_cycle:
; IF (index+1 == len) -> ret
    lhld    gr_stopt_addr
    lda     gr_stopt_index
    inr     a
    sta     gr_stopt_index
    cmp     m
    rz
; Получаем код символа
; A <= M(addr+index+1)
    inr     a
    add     l
    mov     l,a
    mvi     a,$00
    adc     h
    mov     h,a
    mov     a,m
; Если пробел, разбираем отдельно
; IF (A==$20) ->
    cpi     $20
    jnz     gr_stopt_1
; xl = xl + 4 + gap_const
    lhld    xl
    lda     gap_const
    adi     $04
    add     l
    mov     l,a
    mvi     a,$00
    adc     h
    mov     h,a
    shld    xl
    jmp     gr_stopt_cycle
; Else, (A!=$20) ->
gr_stopt_1:
    sta     now_sym
    call    WRSYM_INSIDE
; IF (wrsym error) -> ret
;rc
    lhld    xk
    lda     gap_const
    add     l
    mov     l,a
    mvi     a,$00
    adc     h
    mov     h,a
    shld    xl
    jmp     gr_stopt_cycle


;
; Функция GR_STMONO - отрисовка строки пропорционального текста
;
; Ввод:  Адрес начала строки в памяти:
;        stack+6 -- gr_stmono_addr (word)
;        Начальный адрес отрисовки (верхний левый угол строки):
;        stack+4 -- x_str (int)
;        stack+2 -- y_str (int)
;        Расстрояние между символами: gap_const (byte)
;        Адрес начала таблицы шрифтов: font_const (word)
; Вывод: gr_stopt_index (byte) -- оконечный индекс строки
;        
; Используемые регистры: все
; Читаемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - intersection_style (word)
;  - vert_sym (byte)
;  - hor_sym (byte)
;  - font_const (word)
;  - x_str (int)
;  - y_str (int)
;  - gr_stmono_addr (word)
;  - gap_const (byte)
; Используемая память:
;  - vert_count (byte)
;  - hor_count (byte)
;  - now_sym (byte)
;  - xk (int)
;  - x (int)
;  - y (int)
;  - xl (int)
;  - yl (int)
;  - wrsym_bool_err (byte)
;  - gr_stmono_index (byte)
; Используемые функции:
;  - MUX16
;  - BITSET
;  - GR_DOT_INSIDE
;  - WRSYM
;  - CMP16
;
; Длина:  байта
; Время выполнения: ?
;
; Начало кода:

GR_STMONO_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0C
;Чтение n=3 переменных
    lhlx
    shld    y_str
    inx     d
    inx     d
    lhlx
    shld    x_str
    inx     d
    inx     d
    lhlx
    shld    gr_stmono_addr
GR_STMONO_INSIDE:
; xk <= xl
    lhld    x_str
    shld    xl
    shld    xk
    lhld    y_str
    shld    yl
; index <= -1
    mvi     a,$FF
    sta     gr_stmono_index
gr_stmono_cycle:
; IF (index+1 == len) -> ret
    lhld    gr_stmono_addr
    lda     gr_stmono_index
    inr     a
    sta     gr_stmono_index
    cmp     m
    rz
; Получаем код символа
; A <= M(addr+index+1)
    inr     a
    add     l
    mov     l,a
    mvi     a,$00
    adc     h
    mov     h,a
    mov     a,m
    sta     now_sym
    call    WRSYM_INSIDE
; IF (wrsym error) -> ret
;rc
; xl += hor_sym + gap_const - 1
    lhld    xl
    lda     gap_const
    mov     b,a
    lda     hor_sym
    dcr     a
    add     b
    add     l
    mov     l,a
    mvi     a,$00
    adc     h
    mov     h,a
    shld    xl
    jmp     gr_stmono_cycle



;
; Функция GR_LINE - рисование линий
;
; Ввод:  stack+8 -- x0_line (int) -- координаты начала и конца
;        stack+6 -- y0_line (int)
;        stack+4 -- x1_line (int)
;        stack+2 -- y1_line (int)
; Вывод: нет
;
; Используемые регистры: все
; Читаемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - intersection_style (word)
;  - x0_line
;  - x1_line
;  - y0_line
;  - y1_line
; Используемая память:
;  - dx (int)
;  - dy (int)
;  - dx_puoli (int)
;  - dy_puoli (int)
;  - var_err (int)
;  - xplus (int)
;  - yplus (int)
;  - x (int)
;  - y (int)
; Используемые функции:
;  - MUL16
;  - ABS
;  - BITSET
;  - CMP16
;  - SUB16
;  - GR_DOT_INSIDE
;
; Длина:  байт
; Время выполнения:  тактов
;
; Начало кода:

GR_LINE_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0C
;Чтение n=4 переменных
    lhlx
    shld    y1_line
    inx     d
    inx     d
    lhlx
    shld    x1_line
    inx     d
    inx     d
    lhlx
    shld    y0_line
    inx     d
    inx     d
    lhlx
    shld    x0_line
GR_LINE_INSIDE:
; set var_err
    lxi     h,$0000
    shld    var_err
; settings x
    lhld    x0_line
    shld    x
    xchg
    lhld    x1_line
    call    SUB16
    mov     a,h
    ora     a
    lxi     b,$0001
    jp      gr_line_1
    dcx     b
    dcx     b
    call    ABS
gr_line_1:
    shld    dx
    ora     a
    mov     a,h
    rar
    mov     h,a
    mov     a,l
    rar
    mov     l,a
    shld    dx_puoli
    mov     h,b
    mov     l,c
    shld    xplus
; settings y
    lhld    y0_line
    shld    y
    xchg
    lhld    y1_line
    call    SUB16
    mov     a,h
    ora     a
    lxi     b,$0001
    jp      gr_line_2
    dcx     b
    dcx     b
    call    ABS
gr_line_2:
    shld    dy
    ora     a
    mov     a,h
    rar
    mov     h,a
    mov     a,l
    rar
    mov     l,a
    shld    dy_puoli
    mov     h,b
    mov     l,c
    shld    yplus
; IF (dy/dx) >= 1 -> yrun
; Else -> xrun
    lhld    dx
    xchg
    lhld    dy
    call    CMP16
; IF (dy >= dx)
    jnc     gr_line_yrun
gr_line_xrun:
    call    GR_DOT_INSIDE
; IF (x == x1) -> ret
    lhld    x
    xchg
    lhld    x1_line
    call    CMP16
    rz
; x += xplus
    lhld    xplus
    dad     d
    shld    x
; var_err += dy
    lhld    var_err
    xchg
    lhld    dy
    dad     d
    shld    var_err
; IF (var_err < dx_puoli) -> xrun
    xchg
    lhld    dx_puoli
    xchg
    call    CMP16
    jm      gr_line_xrun
; Else
; y += yplus
; var_err -= dx
    xchg
    lhld    dx
    xchg
    call    SUB16
    shld    var_err
    lhld    yplus
    xchg
    lhld    y
    dad     d
    shld    y
    jmp     gr_line_xrun
gr_line_yrun:
    call    GR_DOT_INSIDE
; IF (y == y1) -> ret
    lhld    y
    xchg
    lhld    y1_line
    call    CMP16
    rz
; y += yplus
    lhld    yplus
    dad     d
    shld    y
; var_err += dx
    lhld    var_err
    xchg
    lhld    dx
    dad     d
    shld    var_err
; IF (var_err < dy_puoli) -> yrun
    xchg
    lhld    dy_puoli
    xchg
    call    CMP16
    jm      gr_line_yrun
; Else
; x += xplus
; var_err -= dy
    xchg
    lhld    dy
    xchg
    call    SUB16
    shld    var_err
    lhld    xplus
    xchg
    lhld    x
    dad     d
    shld    x
    jmp     gr_line_yrun


;
; Функция GR_CIRCLE - рисование окружностей
;
; Ввод:  Координаты центра:
;        stack+6 -- x_circle (int)
;        stack+4 -- y_circle (int)
;        Радиус окружности:
;        stack+2 -- radius (int)
;        Если радиус меньше 0, берется модуль
; Вывод: нет
;        
; Используемые регистры: все
; Читаемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - intersection_style (word)
;  - x_circle
;  - y_circle
;  - radius
; Используемая память:
;  - x (int)
;  - y (int)
;  - x_sector
;  - y_sector
;  - xplus
;  - yplus
;  - x_and_xplus_quar
;  - y_and_xplus_quar
;  - sector_ph
;  - sector_pd
;  - sector_pv
;  - r_quar
; Используемые функции:
;  - SUB16
;  - MUL16
;  - CMP16
;  - BITSET
;  - ABS
;  - GR_DOT_INSIDE
;  - <sector>
;
; Длина:  байта
; Время выполнения: ?
;
; Начало кода:

GR_CIRCLE_USR:
    call    SYS_OS_muutos
;DE <- SP+12
    ldsi    $0C
;Чтение n=3 переменных
    lhlx
    shld    radius
    inx     d
    inx     d
    lhlx
    shld    y_circle
    inx     d
    inx     d
    lhlx
    shld    x_circle
GR_CIRCLE_INSIDE:
; x_sector = 0
    lxi     h,$0000
    shld    x_sector
; y_sector = R
    lhld    radius
    call    ABS
    shld    y_sector
; I sector of circle
    lxi     h,$0001
    shld    xplus
    lxi     h,$FFFF
    shld    yplus
    call    sector
; IV sector of circle
    lxi     h,$FFFF
    shld    xplus
    call    sector
; III sector of circle
    lxi     h,$0001
    shld    yplus
    call    sector
; II sector of circle
    lxi     h,$0001
    shld    xplus
    call    sector
    ret

; x_circle
; y_circle
; radius

; x_sector
; y_sector
; xplus
; yplus
; x_and_xplus_quar
; y_and_xplus_quar
; sector_ph
; sector_pd
; sector_pv
; r_quar

sector:
; r_quar = R^2
    lhld    radius
    mov     d,h
    mov     e,l
    call    MUL16
    shld    r_quar
sector_cycle:
; x_and_xplus_quar
    lhld    x_sector
    xchg
    lhld    xplus
    dad     d
    mov     d,h
    mov     e,l
    call    MUL16
    shld    x_and_xplus_quar
; y_and_xplus_quar
    lhld    y_sector
    xchg
    lhld    yplus
    dad     d
    mov     d,h
    mov     e,l
    call    MUL16
    shld    y_and_xplus_quar
; sector_ph = |x_and_xplus_quar + y*y - r_quar|
    lhld    y_sector
    mov     d,h
    mov     e,l
    call    MUL16
    xchg
    lhld    x_and_xplus_quar
    dad     d
    xchg
    lhld    r_quar
    xchg
    call    SUB16
    call    ABS
    shld    sector_ph
; sector_pd = |x_and_xplus_quar + y_and_xplus_quar - r_quar|
    lhld    x_and_xplus_quar
    xchg
    lhld    y_and_xplus_quar
    dad     d
    xchg
    lhld    r_quar
    xchg
    call    SUB16
    call    ABS
    shld    sector_pd
; sector_pv = |x*x + y_and_xplus_quar - r_quar|
    lhld    x_sector
    mov     d,h
    mov     e,l
    call    MUL16
    xchg
    lhld    y_and_xplus_quar
    dad     d
    xchg
    lhld    r_quar
    xchg
    call    SUB16
    call    ABS
    shld    sector_pv
    lhld    sector_pd
    xchg
    lhld    sector_ph
    call    CMP16
    jnc     sector_1
; -IF (ph < pd)
    xchg
    lhld    sector_pv
    xchg
    call    CMP16
    jnc     sector_2
; IF (ph < pv)
    lhld    x_sector
    xchg
    lhld    xplus
    dad     d
    shld    x_sector
    jmp     sector_4
sector_2:
; Else
    lhld    y_sector
    xchg
    lhld    yplus
    dad     d
    shld    y_sector
    jmp     sector_4
sector_1:
; -IF (ph >= pd)
; DE - Pd
    lhld    sector_pv
    xchg
    call    CMP16
    jnc     sector_2
    lhld    x_sector
    xchg
    lhld    xplus
    dad     d
    shld    x_sector
    jmp     sector_2
sector_4:
; x = x_sector + x0
    lhld    x_circle
    xchg
    lhld    x_sector
    dad     d
    shld    x
; y = y_sector + y0
    lhld    y_circle
    xchg
    lhld    y_sector
    dad     d
    shld    y
    call    GR_DOT_INSIDE
; IF (x_sector == 0) or (y_sector == 0) -> out
    lhld    x_sector
    mov     a,l
    ora     h
    rz
    lhld    y_sector
    mov     a,l
    ora     h
    rz
    jmp     sector_cycle


;
; Функция GR_FRAME - рисование скругленных прямоугольников
;
; Ввод:  -Координаты левого верхнего и правого нижнего
;        углов прямоугольника:
;        stack+10 -- x0_frame
;        stack+8 -- y0_frame
;        stack+6 -- x1_frame
;        stack+4 -- y1_frame (int)
;        -Радиус скругления: stack+2 -- radius (int)
;        Если радиус меньше 0, берется модуль
; Вывод: нет
;        
; Используемые регистры: все
; Читаемая память:
;  - x_sc_right (int) ; правая граница
;  - x_sc_left  (int) ; левая граница
;  - y_sc_upper (int) ; верхняя граница
;  - y_sc_lower (int) ; нижняя граница
;  - num_x_sc_bytes (byte)
;  - start_buf_addr (word)
;  - intersection_style (word)
;  - x0_frame
;  - y0_frame
;  - x1_frame
;  - y1_frame
;  - radius
; Используемая память:
;  - x (int)
;  - y (int)
;  - x_sector
;  - y_sector
;  - xplus
;  - yplus
;  - x_and_xplus_quar
;  - y_and_xplus_quar
;  - sector_ph
;  - sector_pd
;  - sector_pv
;  - r_quar
;  - x_circle
;  - y_circle
; Используемые функции:
;  - SUB16
;  - MUL16
;  - CMP16
;  - BITSET
;  - ABS
;  - GR_DOT_INSIDE
;  - GR_LINE
;  - <sector>
;
; Длина:  байта
; Время выполнения: ?
;
; Начало кода:

;GR_FRAME_USR:
;    call    SYS_OS_muutos
;;DE <- SP+12
;    ldsi    $0C
;;Чтение n=5 переменных
;; x0_frame
;; x1_frame
;; y0_frame
;; y1_frame
;    lhlx
;    shld    radius
;    inx     d
;    inx     d
;    lhlx
;    shld    y1_frame
;    inx     d
;    inx     d
;    lhlx
;    shld    x1_frame
;    inx     d
;    inx     d
;    lhlx
;    shld    y0_frame
;    inx     d
;    inx     d
;    lhlx
;    shld    x0_frame
;GR_FRAME_INSIDE:
;; Предустановка x_sector & y_sector
;; x_sector = 0
;; y_sector = R
;    lxi     h,$0000
;    shld    x_sector
;    lhld    radius
;    call    ABS
;    shld    y_sector
;; Рисуем сектор I(IV)
;; x_circle = (x1-R)
;; y_circle = (y1-R)
;; xplus = 1
;; yplus = -1
;    lhld    radius
;    xchg
;    lhld    x1_frame
;    call    SUB16
;    shld    x_circle
;    lhld    radius
;    xchg
;    lhld    y1_frame
;    call    SUB16
;    shld    y_circle
;    lxi     h,$0001
;    shld    xplus
;    lxi     h,$FFFF
;    shld    yplus
;    call    sector
;; Рисуем сектор IV(I)
;; x_circle = (x1-R)
;; y_circle = (y0+R)
;; xplus = -1
;; yplus = -1
;    lhld    radius
;    xchg
;    lhld    y0_frame
;    dad     d
;    shld    y_circle
;    lxi     h,$FFFF
;    shld    xplus
;    call    sector
;; Рисуем сектор III(II)
;; x_circle = (x0+R)
;; y_circle = (y0+R)
;; xplus = -1
;; yplus = 1
;    lhld    radius
;    xchg
;    lhld    x0_frame
;    dad     d
;    shld    x_circle
;    lxi     h,$0001
;    shld    yplus
;    call    sector
;; Рисуем сектор II(III)
;; x_circle = (x0+R)
;; y_circle = (y1-R)
;; xplus = 1
;; yplus = 1
;    lhld    radius
;    xchg
;    lhld    y1_frame
;    call    SUB16
;    shld    y_circle
;    lxi     h,$0001
;    shld    xplus
;    call    sector
;; line((x1-R);y1)((x0+R);y1)
;    lhld    radius
;    xchg
;    lhld    x1_frame
;    call    SUB16
;    shld    x0_line
;    lhld    radius
;    xchg
;    lhld    x0_frame
;    dad     d
;    shld    x1_line
;    lhld    y1_frame
;    shld    y0_line
;    shld    y1_line
;    call    GR_LINE_INSIDE
;; line((x1-R);y0)((x0+R+1);y0)
;    lhld    y0_frame
;    shld    y0_line
;    shld    y1_line
;    call    GR_LINE_INSIDE
;; line(x0;(y1-R))(x0;(y0+R))
;    lhld    radius
;    xchg
;    lhld    y1_frame
;    call    SUB16
;    shld    y0_line
;    lhld    radius
;    xchg
;    lhld    y0_frame
;    dad     d
;    shld    y1_line
;    lhld    x0_frame
;    shld    x0_line
;    shld    x1_line
;    call    GR_LINE_INSIDE
;; line(x1;(y1-R))(x1;(y0+R))
;    lhld    x1_frame
;    shld    x0_line
;    shld    x1_line
;    jmp     GR_LINE_INSIDE
