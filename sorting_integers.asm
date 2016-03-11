TITLE Sorting Random Integers

; Author:              Patrick Armitage
; Date:                02/27/2016
; Description: A MASM program which receives as input the number of random 
;              numbers a user wants generated in the range of [100 .. 999].
;              User can generate between 10 to 200 numbers.  Once numbers are
;              randomly generated, program first prints the unsorted list, then
;              sorts the numbers using bubblesort implementation, and calculates
;              the median of the array of sorted numbers, printing its result
;              and finally printing the list of sorted numbers

INCLUDE Irvine32.inc

.data
MIN         EQU   10   ; lowest valid number user is allowed to enter
MAX         EQU   200  ; highest valid number user is allowed to enter
LO          EQU   100  ; low end of number range, no num can be less than 100
HI          EQU   999  ; high end of number range, no num can be > than 999
programmer  BYTE  "Patrick Armitage",0
intro_1     BYTE  "Sorting Random Integers         Programmed by ",0
intro_2     BYTE  "This program generates numbers in the range [100 .. 999],",0dh,0ah
            BYTE  "displays the original list, sorts the list, and calculates the",0dh,0ah
            BYTE  "median value.  Finally, it displays the list sorted in descending order.",0
prompt      BYTE  "How many numbers should be generated? [10 .. 200]: ",0
outofrange  BYTE  "Invalid input",0
arrayTitle  BYTE  "The unsorted random numbers:",0
medianTitle BYTE  "The median is ",0
sortedTitle BYTE  "The sorted list:",0
colSpace    BYTE  "   ",0
period      BYTE  ".",0
numTerms    DWORD ?          ; user enters
array       DWORD MAX DUP(?) ; initialize array of size MAX

.code
;########## INTRODUCTION PROCEDURE
; print introductory information to the user.  Expects stack parameters intro_1,
; programmer and intro_2 OFFSETs to print the strings
introduction PROC
  push  ebp
  mov   ebp, esp
  ; Introduce this program
  mov   edx, [ebp+16]         ; mov intro_1 OFFSET to edx
  call  WriteString
  mov   edx, [ebp+12]         ; mov programmer OFFSET to edx
  call  WriteString
  call  CrLf
; Explain the rules of entering valid number of terms
  mov   edx, [ebp+8]          ; mov intro_2 OFFSET to edx
  call  WriteString
  call  CrLf
  pop   ebp
  ret   12
introduction ENDP

;########## GET NUMBER OF TERMS
; prompt user for number of terms and validate user input is within range.
; Expects stack parameters prompt, outofrange and numterms OFFSETS.  Uses
; OFFSET of numTerms rather than value so it can store user input into numTerms
getUserData PROC
get_terms:
  push  ebp
  mov   ebp, esp
  mov   edx, [ebp+16]      ; mov prompt to edx
  call  WriteString
  call  ReadInt
  mov   edi, [ebp+8]       ; mov offset of numTerms into edi
  mov   [edi], eax       ; save the number of terms
validate_terms:
  mov   eax, [edi]
  cmp   eax, MIN           ; validates numTerms is >= 10
  jl    invalid
  cmp   eax, MAX
  jg    invalid            ; validates numTerms is <= 200
  jmp   valid
invalid:
  mov   edx, [ebp+12]      ; mov outofrange to edx
  call  WriteString
  call  CrLf
  jmp   reissue_prompt
reissue_prompt:            ; repeats prompt issued originally
  mov   edx, [ebp+16]      ; mov prompt to edx
  call  WriteString
  call  ReadInt
  mov   [edi], eax       ; store result in numTerms
  jmp   validate_terms
valid:
  pop   ebp
  ret   12
getUserData ENDP

;########## GENERATE RANDOM ARRAY
; generate array of n numbers where n = user input, within the range of 100-999.
; It expects two parameters pushed to the stack, the offset of the array and
; the value of numTerms
generateRandom PROC
  push  ebp
  mov   ebp, esp
  mov   edi, [ebp+12]  ; mov array OFFSET to edi
  mov   edx, 0         ; edx is used as array index incrementer
  mov   ecx, [ebp+8]   ; mov numTerms to ecx
;  dec   ecx
fillArray:
  mov   eax, HI
  sub   eax, LO        ; get the difference between HI and LO for range
  inc   eax            ; increment it, in this case equaling 900
  call  RandomRange    ; returns a random number 0-899 (num < 900)
  add   eax, LO        ; add LO back, range goes from [0 .. 899] to [100 .. 999]
  mov   [edi+edx], eax ; store result in current array index position
  add   edx, 4         ; inc to next array index position
  loop  fillArray      ; loop until ecx, originally numTerms, is 0
  pop   ebp
  ret   8
generateRandom ENDP

;########## DISPLAY CONTENTS OF ARRAY
; displays the contents of the array in rows of 10.  Procedure expects 4
; arguments pushed to the stack, the title, the colSpace, the offset of the
; array, and the numTerms variable that stores the user input
displayArray PROC
  push  ebp
  mov   ebp, esp
printArrayTitle:
  mov   edx, [ebp+20]  ; mov title to edx
  call  WriteString
  call  CrLf
setup:
  mov   edi, [ebp+12]  ; mov array OFFSET to edi
  mov   esi, 0         ; using edx as base index counter
  mov   ecx, [ebp+8]   ; mov numTerms to ecx
  mov   ebx, 0         ; used to count num terms written
  mov   edx, [ebp+16]  ; mov colSpace to edx to print
loopDisplay:
  mov   eax, [edi+esi] ; mov current array index position into eax to write
  call  WriteDec
  inc   ebx            ; increment number of terms written in row thus far
  cmp   ebx, 10        ; if terms in row = 10, we jump to end the line
  je    endLine
  call  WriteString    ; edx contains colspace during the entire loop
  jmp   endDisplayLoop
endLine:
  cmp   ecx, 1         ; if last loop, don't print this CrLf
  je    endDisplayLoop
  call  CrLf           ; start a new line of terms
  mov   ebx, 0         ; set num terms written back to 0 for next line
endDisplayLoop:
  add   esi, 4         ; increment array index counter in each loop
  loop  loopDisplay
  call  CrLf
  pop   ebp
  ret   16
displayArray ENDP

;########## SORT THE ARRAY'S NUMBERS
; uses an an augmented implementation of Kip Irvine's bubblesort MASM
; implementation, borrowed from pages 374-375 of Assembly Language for x86
; Processors textbook.  Bubblesort functions by iterating over the array in
; O(n^2) complexity, swapping each pair of adjacent indices per iteration when
; the lesser is ahead of the greater, until at the last iteration the greatest
; is in the first place and the least in the last place, in descending order
sortArray PROC
  push  ebp
  mov   ebp, esp
  mov   edi, [ebp+12]  ; mov array OFFSET to edi
  mov   ecx, [ebp+8]   ; mov numTerms to ecx
  dec   ecx
  mov   edx, 0
outerLoop:
  push  ecx            ; store ecx because we numTerms innerloops for each outer
  mov   esi, edi       ; we keep the pointer to the first element in edi
innerLoop:
  mov   eax, [esi]     ; move array element for comparison
  cmp   [esi+4], eax   ; and compare it with the next element
  jl    endInner       ; if the next element is less, dec order already, no xchg
  xchg  eax, [esi+4]   ; put prev element in next element place
  mov   [esi], eax     ; and next element in prev element place
endInner:
  add   esi, 4         ; we increment to next array element for next loop
  loop  innerLoop
endOuter:
  pop   ecx            ; back to outer loop, get original ecx value again
  loop  outerLoop
endSort:
  pop   ebp
  ret   8
sortArray ENDP

;########## CALCULATE THE MEDIAN OF THE ARRAY
; calculate and print the median of the display by dividing numTerms by 2 and
; finding the "middle index" value in the array.  If numterms is odd, it has a
; true middle index, and that is printed.  If numTerms is even, it has "two"
; middle indices, and their average is calculated and rounded, then printed
calculateMedian PROC
  push  ebp
  mov   ebp, esp
printMedianTitle:
  mov   edx, [ebp+20]  ; mov title to edx
  call  WriteString
setup:
  mov   edi, [ebp+12]  ; mov array address into edi
  mov   eax, [ebp+8]   ; mov numTerms into eax
  cdq
  xor   edx, edx       ; clear edx for division
  mov   ebx, 2
  div   ebx
  cmp   edx, 1
  je    printOddMedian    ; if remainder = 1, num is odd and div result = median
printEvenMedian:
  mov   ebx, 4
  mul   ebx
  mov   ebx, eax
  mov   eax, [edi+ebx]    ; we need the first middle index
  sub   ebx, 4            ; then inc array address down to second middle index
  add   eax, [edi+ebx]    ; and add them together
  cdq
  xor   edx, edx
  mov   ebx, 2            ; find average of the two by dividing by two
  div   ebx
  cmp   edx, 1
  je    incAvg            ; if average has remainder of 1, round up
  jmp   finishEvenMedian
incAvg:
  add   eax, 1
finishEvenMedian:
  call  WriteDec
  jmp   printPeriod
printOddMedian:
  mov   ebx, 4
  mul   ebx
  mov   eax, [edi+eax]    ; in odd numTerms case we just print middle index num
  call  WriteDec
printPeriod:
  mov   edx, [ebp+16]  ; mov period to edx
  call  WriteString
  call  CrLf
  pop   ebp
  ret   16
calculateMedian ENDP

main PROC
; create "random" seed based on current system clock
  call  Randomize
; introduce this program
  push  OFFSET intro_1
  push  OFFSET programmer
  push  OFFSET intro_2
  call  introduction
  call  CrLf
; get number of terms to sort and print from user
  push  OFFSET prompt
  push  OFFSET outofrange
  push  OFFSET numTerms
  call  getUserData
  call  CrLf
; populate array with random numbers [100 .. 999]
  push  OFFSET array
  push  numTerms
  call  generateRandom
; print unsorted array
  push  OFFSET arrayTitle
  push  OFFSET colSpace
  push  OFFSET array
  push  numTerms
  call  displayArray
  call  CrLf
; sort the array with bubblesort
  push  OFFSET array
  push  numTerms
  call  sortArray
; get and print median of sorted array
  push  OFFSET medianTitle
  push  OFFSET period
  push  OFFSET array
  push  numTerms
  call  calculateMedian
  call  CrLf
; print the sorted array
  push  OFFSET sortedTitle
  push  OFFSET colSpace
  push  OFFSET array
  push  numTerms
  call  displayArray
; exit to operating system
  exit
main ENDP

END main
