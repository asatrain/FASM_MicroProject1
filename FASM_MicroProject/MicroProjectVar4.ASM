format PE console

entry start

include 'win32a.inc'

; ������ ������
section '.data' data readable writable

        ; ������-������ ������������� �����
        floatFormat db '%lf', 0

        ; ����� ����� ����
        enterXText db 'Enter x in [%dpi, %dpi]: ', 0

        ; ����� ���������� �������� � ������� ����� �������� ��������
        cosXResultText db 'Computed with mathematical series cos(%lf) = %lf', 10, 0

        ; ����� ���������� �������� � ������� FCOS �������� ��������
        realCosXResultText db 'Computed with FCOS cos(%lf) = %lf', 10, 0

        ; ����� ��������� ������������ ������ �� ���������� ������� ���������� ����
        xOutOfBoundsText db 'Entered x is not in allowed bounds...', 10, 0


        ; ������� �������� ����������, ������������ � ����������� ������������������
        percentMultiplyer dq 0.001

        ; �����������, �������� ������� ������� (������� ������� = PI * higherBoundPI)
        higherBoundPI dd 5

        ; �����������, �������� ������ ������� (������ ������� = PI* lowerBoundPI)
        lowerBoundPI dd -5


        ; ������� ����� ����
        sum dq 0.0

        ; ���������� ���� ����
        prevTerm dq 1.0

        ; ������� �������� ���������
        n dd 0

        ; ��������� ���� � ��������
        x dq ?

        ; ��������� ���������� ��� �������� ����� �����
        intTmp dd ?

        ; ��������� ���������� ��� �������� ������������ �����
        floatTmp dq ?

        NULL = 0

; ������ ����
section '.code' code readable executable

; ����� ����� ���������
start:
        call readX
        call countCosX
        call printCosX
        call printRealCosX

; �������� ������� ������� ��� ���������� ������ ���������
finish:
        invoke getch
        push NULL
        invoke ExitProcess

; �������� ����� ����
proc readX

        ; ���������� ������������ ����� � ������
        invoke printf, enterXText, [lowerBoundPI], [higherBoundPI]
        add esp, 12
        invoke scanf, floatFormat, x
        add esp, 8

        ; �������� �� ����� �� ������� �������
        FLDPI
        FIMUL [higherBoundPI]
        FLD [x]
        FCOMPP
        FSTSW ax
        SAHF
        ja xOutOfBounds

        ; �������� �� ����� �� ������ �������
        FLDPI
        FIMUL [lowerBoundPI]
        FLD [x]
        FCOMPP
        FSTSW ax
        SAHF
        jb xOutOfBounds

        ret

; ��������� ������ �� �������
xOutOfBounds:
        invoke printf, xOutOfBoundsText
        add esp, 4
        jmp finish

endp

; ��������� �������� � ������� ���������� ���� �������� ��������
proc countCosX

        ; ������������� ������������
        FINIT

; ������ ����� ����������������� ������������ ������ ����
sumLoop:
        ; ++n, sum += prevTerm
        inc [n]
        FLD [sum]
        FADD [prevTerm]
        FSTP [sum]

        ; prevTerm *= -1 * x * x / (2n) / (2n - 1)
        FLD [prevTerm]
        FCHS
        FMUL [x]
        FMUL [x]
        mov eax, [n]
        imul eax, 2
        mov [intTmp], eax
        FIDIV [intTmp]
        dec [intTmp]
        FIDIV [intTmp]
        FSTP [prevTerm]

        ; ���� ��������� abs(prevTerm) <= percentMultiplyer * sum, ������� �� �����
        FLD [percentMultiplyer]
        FMUL [sum]
        FABS
        FLD [prevTerm]
        FABS
        FCOMPP
        FSTSW ax
        SAHF
        jbe sumLoopEnd

        ; ���� �� abs(prevTerm) > percentMultiplyer * sum, ��
        ; ��������� ��������� �������� �����
        jmp sumLoop
sumLoopEnd:
        ret

endp

; ��������� ������ ������������� �������� ��������
proc printCosX

        invoke printf, cosXResultText, dword[x], dword[x + 4],\
                                       dword[sum], dword[sum + 4]
        add esp, 20

        ret

endp

; ��������� ������ "�������" �������� �������� � ������� FCOS
proc printRealCosX

        FLD [x]
        FCOS
        FSTP [floatTmp]
        invoke printf, realCosXResultText, dword[x], dword[x + 4],\
                                           dword[floatTmp], dword[floatTmp + 4]
        add esp, 20

        ret

endp

; ������ �������
section '.idata' import data readable

library kernel, 'kernel32.dll',\
        msvcrt, 'msvcrt.dll'

import kernel,\
       ExitProcess, 'ExitProcess'

import msvcrt,\
       printf, 'printf',\
       scanf, 'scanf',\
       getch, '_getch'