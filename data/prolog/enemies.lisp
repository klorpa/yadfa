;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa-enemies"; coding: utf-8-unix; -*-
(in-package :yadfa-enemies)
(defmacro make-instances (&rest symbols)
  `(list ,@(iter (for symbol in symbols)
                 (collect `(make-instance ',symbol)))))
(defclass catchable-enemy (enemy)
  ((catch-chance-rate%
    :initarg catch-chance-rate
    :accessor catch-chance-rate-of
    :initform 1
    :type (real 0 1)
    :documentation "Chance of @var{CATCH-CHANCE} in 1 that this enemy can be caught where @var{CATCH-CHANCE} is a number between 0 and 1. If it is an object that can be coerced into a function, it is a function that accepts this enemy as an argument that returns a number.")))
(defmethod catch-chance ((enemy catchable-enemy))
  (/ (* (- (* 3 (calculate-stat enemy :health)) (* 2 (health-of enemy))) (catch-chance-rate-of enemy))
     (* 3 (calculate-stat enemy :health))))
(defclass adoptable-enemy (enemy) ())
(defclass skunk-boop-mixin (base-character) ())
(defmethod change-class-text ((class adoptable-enemy))
  (format nil "~a was adopted" (name-of class)))
