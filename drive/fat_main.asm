
.def FAT_CLUSTER =              $0001
.def SYSCELL_DISKBUF_ADDR =     $FF1E
.def SYSCELL_STRBUF8 =          $FF20
.def SYSCELL_STRBUF8P1 =        $FF21

.def DISK_CLUSTER_ERASE =   W25_SECTOR_ERASE
.def DISK_CLUSTER_WRITE =   W25_SECTOR_WRITE
.def DISK_CLUSTER_READ =    W25_SECTOR_READ


; FAT_FIND_NEXT_CLUSTER - поиск номера следующего кластера файла/субдиректории
; Ввод:  (SP+2) - номер текущего кластера
; Вывод: (SP+2) - номер следующего кластера
;        Флаг C - если равен 0, то успешно, если 1, то следующего кластера нет
; Используемые регистры: все
; Читаемая память: SYSCELL_DISKBUF_ADDR
; Используемая память: массив DISKBUF (длины $1000)
; Используемые функции:
;  - DISK_CLUSTER_READ
;  - CMP16
; Оценка: длина - , время - 

FAT_FIND_NEXT_CLUSTER:
;Копируем кластер FAT в буфер
    lxi     h,FAT_CLUSTER
    push    h
    lhld    SYSCELL_DISKBUF_ADDR
    push    h
    call    DISK_CLUSTER_READ
;По адресу (SYSCELL_DISKBUF_ADDR+CLUST_NUM) считываем значение NEXT
    pop     d
    lhld    SYSCELL_DISKBUF_ADDR
    dad     d
    mov     e,m
    inx     h
    mov     d,m
    xchg        ;(HL)-NEXT
;Сравниваем NEXT c $FFF0
    lxi     d,$FFF0
    call    CMP16   ;если C==0, то ошибка
    push    h
    cmc             ;если С==1, то ошибка
    ret


; FAT_FIND_BY_NAME - поиск номера первого кластера файла/субдиректории по имени
; Ввод:  (SP+4) - начальный адрес строки, сод имя искомого файла
;        (SP+2) - номер начального кластера директории, в которой ведем поиск
; Вывод: (SP+2) - номер первого кластера найденного файла/субдиректории
;        Флаг С - если равен 0, то успешно, если 1, то не удалось найти
; Используемые регистры: все
; Используемая память: массив DISKBUF (длины $1000)
; Используемые функции:
;  - DISK_CLUSTER_READ
;  - CMP16
;  - COPCOUNT
;  - FAT_FIND_NEXT_CLUSTER
; Оценка: длина - , время - 

FAT_FIND_BY_NAME:
    mvi     a,$08
    sta     SYSCELL_STRBUF8
fat_fbn_clust_process:
;Копируем кластер адреса LOCAL_CLUST_POINTER в буфер диска
;(SP+4) - начальный адрес строки, сод имя искомого файла
;(SP+2) - номер начального кластера директории, в которой ведем поиск
;(SP+0) - адрес возврата
    ldsi    $02
    lhlx
    push    h
    lhld    SYSCELL_DISKBUF_ADDR
    push    h
    call    DISK_CLUSTER_READ
;Подготовка переменной счетчика и указателя на дескрипторы файлов
    lhld    SYSCELL_DISKBUF_ADDR
    xchg
    mvi     c,$80
fat_fbn_cycle:
    push    b           ;счетчик в С
    push    d           ;указатель на дескриптор файла/субдиректории
;Копируем имя в строку SYSCELL_STRBUF8 (строка должна иметь впереди байт длины)
    lxi     b,$0008
    lxi     h,SYSCELL_STRBUF8P1
    call    COPCOUNT
;(SP+8) - начальный адрес строки, сод имя искомого файла
;(SP+6) - номер начального кластера директории, в которой ведем поиск
;(SP+4) - адрес возврата
;(SP+2) - счетчик в С
;(SP+0) - указатель на дескриптор файла/субдиректории
    ldsi    $08         ;DE <- SP+8
    lhlx
    lxi     d,SYSCELL_STRBUF8
    call    STRCMP ;Z==1 - str1==str2
    pop     d           ;указатель на дескриптор файла/субдиректории
    pop     b           ;счетчик в С
    jz      fat_fbn_equal
;Строки не равны. Переходим к следующему дескриптору
    lxi     h,$0020
    dad     d
    xchg
    dcr     c
    jnz     fat_fbn_cycle
;В текущем кластере не найдено подходящих дескрипторов. Переход к след. кластеру
;(SP+4) - начальный адрес строки, сод имя искомого файла
;(SP+2) - номер начального кластера директории, в которой ведем поиск
;(SP+0) - адрес возврата
    ldsi    $02         ;DE <- SP+2
    lhlx
    push    d           ;SP+2
    push    h           ;(SP+4) LOCAL_CLUSTER_NUMBER
    call    FAT_FIND_NEXT_CLUSTER
    pop     h           ;NEXT_CLUSTER_NUMBER
    pop     d           ;SP+2
;Возврат, если следующего кластера нет
    jc      fat_fbn_return
    shlx                ;сохранить
    jmp     fat_fbn_clust_process
fat_fbn_equal:
;Строки равны. Передаем на вывод номер первого кластера файла/субдиректории
;DE - указатель на дескриптор файла/субдиректории
    lxi     h,$001A     ;26 (смещение номера первого кластера в дескрипторе)
    dad     d
    mov     e,m
    inx     h
    mov     d,m
fat_fbn_return:
;(SP+4) - начальный адрес строки, сод имя искомого файла
;(SP+2) - номер начального кластера директории, в которой ведем поиск
;(SP+0) - адрес возврата
    pop     h
    pop     b
    pop     b
    push    d
    pchl
