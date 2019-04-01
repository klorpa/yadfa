(in-package :yadfa-util)
(defun shl (x width bits)
    "Compute bitwise left shift of x by 'bits' bits, represented on 'width' bits"
    (logand (ash x bits)
        (1- (ash 1 width))))
(defun shr (x width bits)
    "Compute bitwise right shift of x by 'bits' bits, represented on 'width' bits"
    (logand (ash x (- bits))
        (1- (ash 1 width))))
(defmethod lambda-list ((lambda-exp list))
    (cadr lambda-exp))
(defmethod lambda-list ((lambda-exp function))
    (swank-backend:arglist lambda-exp))
(defmacro do-push (item &rest places)
    `(progn ,@(loop for place in places collect `(push ,item ,place))))
(defun remove-nth (n sequence)
    (remove-if (constantly t) sequence :start n :count 1))
(defun insert (list value n)
    (if (<= n 0)
        (cons value list)
        (cons (car list) (insert (cdr list) value (- n 1)))))
(define-modify-macro insertf (value n) insert)
(defun substitute/swapped-arguments (sequence new old &rest keyword-arguments)
    (apply #'substitute new old sequence keyword-arguments))

(define-modify-macro substitutef (new old &rest keyword-arguments)
    substitute/swapped-arguments
    "Modify-macro for SUBSTITUTE. Sets place designated by the first argument to
the result of calling SUSTITUTE with OLD NEW, place, and the KEYWORD-ARGUMENTS.")
(defun random-from-range (start end)
    (+ start (random (+ 1 (- end start)))))