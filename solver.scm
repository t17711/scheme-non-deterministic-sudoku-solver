;; sodoku solver
; Binod Timalsina 
; Khadeeja Din 

;; fill sodoku such that each column and row and nXn subgrid have (1 to n) filled
; there are already some cells filled
;; steps
;; input list of n size with n elements each. so the list is column and inner list is row
;eg 9X9 from websodoku.com
(define x 'x) ; placeholder for empty space


;(define sodoku (list (list x x 4 x 5 x x 3 x)
;                     (list x x 9 x x x x 4 2)
;                     (list 1 x x 4 x 6 9 7 5)
;                     (list x x x 9 4 8 x 6 x)
;                     (list x x 6 x 7 x 2 x x)
;                     (list x 8 x 6 2 3 x x x)
;                     (list 2 4 8 5 x 1 x x 3)
;                     (list 3 1 x x x x 6 x x)
;                     (list x 9 x x 3 x 5 x x)))

;answer , after some try
;((8 7 4 2 5 9 1 3 6)
; (5 6 9 3 1 7 8 4 2)
; (1 2 3 4 8 6 9 7 5)
; (7 5 2 9 4 8 3 6 1)
; (4 3 6 1 7 5 2 8 9)
; (9 8 1 6 2 3 4 5 7)
; (2 4 8 5 6 1 7 9 3)
; (3 1 5 7 9 4 6 2 8)
; (6 9 7 8 3 2 5 1 4))
(define sodoku (list
                (list x x x 4)
                (list x 2 1 x)
                (list x 1 4 x)
                (list x x x 1)))
(define n (length sodoku)) ; length
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; data structurres
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; so we need to do coordinate function to get (i,j) in cell
(define (cord a b)
  (list a b)) ; a is i, b is j , it starts from (0, 0) on top lleft and ends with (n-1,n-1) on botton right

(define (row-number cord)
  (car cord))

;;return the column number for a coordinate
(define (column-number cord)
  (car (cdr cord)))

;;returns the value at the ath coordinate of sodoku board
(define (cell sodoku a)
  (list-ref (list-ref sodoku (row-number a)) (column-number a)))
;; print with errors
(define (print-sodoku l)
  (define (iter row l2)
    (cond ((null? l2) (newline))
          (else
           (newline)
           (display (car l2))
           (display "-")
           (display (car row))
           (iter (cdr row) (cdr l2)))))
  (iter (row-error l) l)
  (display "----------------------------")
  (newline)
  (display (column-error l)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; solve main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (solve-sodoku sodoku)
  (let ((empty-coordinates (get-empty-coordinates sodoku)))
    (let* ((filled-sodoku (fill-sodoku sodoku empty-coordinates)) ; fill sodoku such that sub grid has all 1 to n numbers 
           (stream (infinite-random-stream-from-list empty-coordinates))) ; create the stream of a list containing a sublist that has coordinates of empty places sorted by subgrid
      (let ((x (an-element-of stream))) ; get an element to calculate randomly
        (set! filled-sodoku (random-swap filled-sodoku x)) ; chose 2 element from x list of coordinates and swap them 
        (assert (eq? (total-error filled-sodoku ) 0)) ; if sodoku has no error return 
        (print-sodoku filled-sodoku)
        filled-sodoku))))
; swap random 2 elements from list
(define (random-swap filled-sodoku coordinate-list)
  (let  ((err-sum (total-error filled-sodoku)) ; store old sum
         (temp-sodoku filled-sodoku)) ; store previous sodoku
    (cond ((<= (length coordinate-list) 1)  filled-sodoku) ; no element to swap
          ((eq? (length coordinate-list) 2) (set! temp-sodoku (swap filled-sodoku (car coordinate-list ) (car (cdr coordinate-list))))) ; just 2 element to swap
          (else 
           (let* ((ran (random (length coordinate-list ))) ; select 2 random coordinates
                  (x (list-ref coordinate-list ran))
                  (y (list-ref (append (first-n-elem coordinate-list ran)  (list-tail coordinate-list (+ ran 1))) (random (- (length coordinate-list) 1))))) ; select from list without x     
             (set! temp-sodoku
                   (swap filled-sodoku x y))))) ; swap x y coordinates
    (cond ((<= (total-error temp-sodoku) err-sum) ; if err decreases return temp        
           (print-sodoku filled-sodoku)
           (display "Total error: ") (display err-sum)
           (newline)
           (newline)
           temp-sodoku) ; if error decreases consider else dont
          (else
           filled-sodoku))))

(define (total-error sodoku) ; calculate error in row and column to calculate total error
  (let ((col (column-error sodoku))
        (row (row-error sodoku)))
    (+ (accumulate + 0 col) (accumulate + 0 row ))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; major functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; pre: sodoku has empty space denoted by place-holder and we have coordinbates of those empty spaces
; post : sodoku is filled such that all sqrt(n) * (sqrt(n) have all 1 to n
(define (fill-sodoku sodoku empty-coord)
  (let ((x ( sub-grid-to-row sodoku)); convert sodoku subgrid to columns to easier calculation
        (n-list-n (n-list (length sodoku))) ; get a list of numbers from 1 to n to fill in
        (empty-coordinates (append-sublist empty-coord)))  ; get coordinates of empty cells sorted by subgrid and appemnd them to make easier calculation
    (let ((y (map (lambda (a) (rember-all 'x a)) x))) ; get fixed elements in sodoku
      (let ((z (fringe (map (lambda (a) (minus n-list-n a)) y)))) ; subtract fixed elements in  subgrid by (1 to n) to fill so that this condition is met
        ; also this is same size as empoty-coordinates ao we can fill those coordinates easier
        (fill-from-subgrid sodoku empty-coordinates z)    ; fill all the empty coordinates 
        ))))
;(fill-sodoku sodoku (get-empty-coordinates sodoku)) to get filled
; pre:  pre: sodoku has empty space denoted by place-holder
;post: we get coordinates of place holders sorted by subgrid
(define (get-empty-coordinates sodoku)
  (define (iter i remaining) ; keep track of i
    (define (iter2 j remaining-2) ; keep track of j
      (cond ((null? remaining-2) '())
            (else
             (cond ((eq? (car remaining-2) 'x) ; if we find x we replace it with its coordinate
                    (set! sodoku (change sodoku (cord i j) (cord i j)))))
             (iter2 (+ j 1) (cdr remaining-2))))) ; do it for all element in a row
    (cond ((null? remaining) (newline))
          (else
           (iter2 0 (car remaining))
           (iter (+ i 1) (cdr remaining)))))  ; do it for all rows
  (iter 0 sodoku)
  (map (lambda (x) (remove-numbers x))  (sub-grid-to-row sodoku))) ; sort items by subgrid and then rempove numbers to only keep coordinates


; pre:  pre: sodoku has empty space denoted by place-holder, and we have coordinate and value
; post: in sodoku the item in coordinate is changed to new value
(define (change board coord value)
  (cond ((= (row-number coord) 0) (cons (change-grid (list-ref board (row-number coord)) (column-number coord) value)
                                        (cdr board)))   ; change element in ist row then append keep rest of rows 
        ((= (row-number coord) (- n 1)) (append (first-n-elem board (row-number coord)) ; keep all rows upto last, change in last row and append it
                                                (cons (change-grid (list-ref board (row-number coord)) (column-number coord) value) '())))        
        (else (append (first-n-elem board (row-number coord)) ; keep rows upto row number then add changed row to it and append rows after row number
                      (cons (change-grid (list-ref board (row-number coord)) (column-number coord) value)
                            (list-tail board (+ (row-number coord) 1)))))))  

;pre: we have a sodoku , and two coodinates
; post: we have sodoku with the element in those coordinates swapped
(define (swap board coord1 coord2) ; do general swap, keep track of old values and set coordinated to new values
  (let ((x (cell board coord1)) 
        (y (cell board coord2)))
    (set! board (change board coord1 y)) ; change coordinate cord1 to y
    (set! board (change board coord2 x))); change coordinate cord2 to x
  board
  )

;pre: a sodoku that is filled
;post : a list with numbers of errors in each rows
(define row-error
  (lambda (sodoku)
    (map repetitions sodoku))) ; check of how many repetitions is in list which is error

;pre: a sodoku that is filled
;post : a list with numbers of errors in each column
(define column-error
  (lambda (sodoku)
    (let ((sodoku-tr (transpose sodoku)))  ; transpose and get row error to get column error, transpose function is from lecture notes
      (row-error sodoku-tr))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; auxilairy codes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; fill sodoku list of coordinates with list of items
;pre; sodoku, list of coordinates and list of values, both lists should same size
;post: sodoku has values in the list of coordinates changed to list of values
(define (fill-from-subgrid sodoku subgrid val)
  (if (null? subgrid) sodoku ; if no more thing to change return
      (let ((x (change sodoku (car subgrid) (car val)))) ; change one at a time
        (fill-from-subgrid x (cdr subgrid) (cdr val)))))

;; pre: a is an atom, and lat is a list of atoms
;; post: (rember a lat) is the list lat', where lat' is 
;;obtained from lat by removing the first occurrence -- if any --
;; from lecture note
(define rember
  (lambda (a lat)
    (cond
      ((null? lat) (quote ()))
      ((eq? (car lat) a) (cdr lat))
      (else (cons (car lat) (rember a (cdr lat)))))))

; pre: a list and a value  
; post: a new list without any value entered
; modified code from lecture code
(define rember-all
  (lambda (a lat)
    (cond
      ((null? lat) (quote ()))
      ((eq? (car lat) a) (rember-all a (cdr lat)))
      (else (cons (car lat) (rember-all a (cdr lat)))))))

; pre: a list 
; post: a new list without any numbers
; modified code from lecture code
(define (remove-numbers lat)
  (cond
    ((null? lat) (quote ()))
    ((number? (car lat)) (remove-numbers (cdr lat)))
    (else (cons (car lat) (remove-numbers (cdr lat))))))

; pre: a list of numbers
;post: number of repetitions in a list, (1 1) is 1 repetition
(define (repetitions lst)
  (define (iter b result) ; do a loop that removes all (car b) in (cdr b), then we get a list with uniques only
    (cond ((null? b) result)
          (else
           (let ((x (rember-all (car b) b)))
             (iter x (append result (list (car b))))))))
  
  (let ((x (iter lst (list )))) 
    (- (length lst) (length x)))) ; length of original list - length of uniques is the repetiutions in a list

; pre a 2d list
; post : a transposed list
(define (transpose mat)
  (accumulate-n cons '() mat)) ; accumulate car in a list for n times to get list of transposed matt

; accumulate -n from lecture, does accumulates (function car list) in a list of lists of equal size
; pre: there is a 2d sequence, initial and operation to be done
; post: the operation is performed in all sublist
(define (accumulate-n op init seqs)
  (if (null? (car seqs))
      '()
      (cons (accumulate op init (map car seqs)) ; does operation in all cars and makes list of result
            (accumulate-n op init (map cdr seqs))))) ; sends all cdr to more operation

;pre: a list, operation, and initial value
;post: a list with operation done to all element 
(define (accumulate op initial sequence)
  (if (null? sequence)
      initial
      (op (car sequence)
          (accumulate op initial (cdr sequence)))))

;pre: a list and a value
;post: true if value is in list false otherwise
(define (find a l)
  (cond ((null? l) #f)
        ((eq? (car l) a) #f)
        (else
         (find a (cdr l)))))

; set subtraction, rempve all items inset1 that is also in set 2 set2 is always bigger
;pre: two lists
;post: any element both in l1 and l2 is removed from l1 and returned
(define (minus set1 set2)
  (cond ((null?  set2) set1) ; if no more stuff to remove return set1
        ((null?  set1) '()) ; if all items in sets are removed return empty
        (else
         (minus (rember (car set2) set1) (cdr set2))))) ; remove 1st occurance of car of 2nd list from first

; pre: a numner n
;post: a list of numbers from 1 to n
(define (n-list n)
  (cond ((eq? n 0) '())
        (else
         (cons n (n-list (- n 1))))))

;pre: a list of sublists
;post: list of all atoms in the list
;from lecture
(define (fringe tree)
  (cond ((null? tree) '())
        ((atom? tree) (list tree))
        (else (append (fringe (car tree))
                      (fringe (cdr tree))))))

; pre: a list of lists
;post; a list with all sublists appended, sublist of sublist left alone    
(define (append-sublist tree)
  (cond ((null? tree) '())
        (else
         (append (car tree) (append-sublist (cdr tree))))))
;pre: any input
;post: true if input is aton otherwise false
(define atom?
  (lambda (x)
    (and (not (null? x)) (not (pair? x)))))

;pre: a list and number n
;post: list is divided to smaller list of n size, if not multiole of n last sublist is size less than n
(define (divide-list l n)
  (cond 
    ((> (length l) n) (cons (first-n-elem l n) (divide-list (list-tail l n) n)))
    (else (list l))))

; pre:  a sodoku
;post: a list of all items sorted by subgrids
(define ( sub-grid-to-row sodoku)
  (define (iter sod n) ; this returns list of lists 
    (cond ((null? sodoku) '())
          ((> (length (list-ref sodoku 0)) n)
           (append (map (lambda (x) (first-n-elem x n)) sodoku )    ; get 1st n element of all lists 
                   ( sub-grid-to-row (map (lambda (x) (list-tail x n)) sodoku))))
          (else (map (lambda (x) (first-n-elem x n)) sodoku ))))
  
  (let ((n (sqrt (length sodoku))))
    (let ((lst (iter sodoku n))) ; get a list of smaller list of size sqrt(n)
      (divide-list (append-sublist lst) (* n n)) ;divide that sublist to 9 sublist to get sodoku subgrid as rows;
      ;should not have needed to do append-sublist lst to divide but for some reason it didnt work without it 
      ))) 
;; pre a list and number n
;;post: list of the first n elements of a the entered list
(define (first-n-elem lst n)
  (if (eq? n 0)
      (list)
      (cons (car lst) (first-n-elem (cdr lst) (- n 1)))))

;pre a list, a val, and a number k
;;post: a new list with index replaced by val
(define (change-grid list k val)
  (cond ((eq? k 0) (cons val (cdr list))) ; if index reached cons val to cdr of list
        ((eq? k (- n 1)) (append (first-n-elem list k) (cons val '()))) 
        (else (append (first-n-elem list k) (cons val (list-tail list (+ k 1)))))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;amb
(require compatibility/defmacro)

(define amb-fail '*)

(define initialize-amb-fail
  (lambda ()
    (set! amb-fail
          (lambda ()
            (error "amb tree exhausted")))))


(initialize-amb-fail)

(define-macro amb
  (lambda alts...
    `(let ((+prev-amb-fail amb-fail))
       (call/cc
        (lambda (+sk)
          
          ,@(map (lambda (alt)
                   `(call/cc
                     (lambda (+fk)
                       (set! amb-fail
                             (lambda ()
                               (set! amb-fail +prev-amb-fail)
                               (+fk 'fail)))
                       (+sk ,alt))))
                 alts...)
          
          (+prev-amb-fail))))))

(define assert
  (lambda (pred)
    (if (not pred) (amb))))

;; get an element from infinite stream
(define (an-element-of items)
  (amb (car items) (an-element-of ((cdr items)))))
;(infinite-random-stream-from-list '( 1  2 3 4 5 6 7 8 9))))  gives infinite stream of a emement in list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;stream
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; form able ans sussman book
(define-syntax delay
  (syntax-rules ()
    ((_ exp) (lambda () exp))))

(define-syntax cons-stream
  (syntax-rules ()
    ((_ a b) (cons a (delay b)))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; define a list that gives all the item in infinite stream
(define getlist
  (lambda (str)
    (display (car str))
    (newline)
    (if (eq? (car str) 9)(display "done") ; just a condition to stop stream or else it will keep going on
        (getlist ((cdr str))))))
; get a infinite random stream of numbers from a list
(define (infinite-random-stream-from-list n)
  (let ((x (random (length n))))
    (cons-stream (list-ref n x) (infinite-random-stream-from-list n))))

;(define a (getlist (infinite-random-stream-from-list '( 1  2 3 4 5 6 7 8 9)))) ; gives infinite stream of 


