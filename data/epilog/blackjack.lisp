;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa-blackjack"; coding: utf-8-unix; -*-
(in-package :yadfa-blackjack)
(define-command-table game-commands)
(define-command-table playing-commands :inherit-from (game-commands))
(define-command-table end-round-commands :inherit-from (game-commands))
(define-command-table end-game-commands :inherit-from (game-commands))
(defclass card ()
  ((value :initform nil
          :type (or symbol fixnum)
          :initarg :value
          :accessor value-of)
   (suit :initform nil
         :type symbol
         :initarg :suit
         :accessor suit-of)
   (side :initform :up
         :type keyword
         :initarg :side
         :accessor side-of)))
(defvar *back-card-pattern* (make-rectangular-tile (clim:make-pattern #2A((0 1)
                                                                          (1 0))
                                                                      (list +red+ +white+))
                                                   2 2))
(defvar *player-cards*)
(defvar *ai-cards*)
(defvar *deck*)
(defvar *round*)
(defvar *player-clothes*)
(defvar *checkpoints*)
(defvar *put-on-old-clothes*)
(defgeneric print-potty (user checkpoint had-accident amount &key wear)
  (:method (user checkpoint had-accident amount &key wear)
    (declare (ignore wear))
    t)
  (:method (user (checkpoint (eql :need-to-potty)) had-accident amount &key wear)
    (declare (ignore wear))
    (format t "*~a crosses ~:[her~;his~] legs~%*" (name-of user) (malep user)))
  (:method (user (checkpoint (eql :potty-dance)) had-accident amount &key wear)
    (declare (ignore wear))
    (format t "*~a does a potty dance in ~:[her~;his~] seat*~%" (name-of user) (malep user)))
  (:method (user (checkpoint (eql :potty-desparate)) had-accident amount &key wear)
    (declare (ignore wear))
    (format t "*~a whines and does a potty dance in ~:[her~;his~] seat*~%" (name-of user) (malep user)))
  (:method (user (checkpoint (eql :lose)) had-accident (amount (eql :dribble)) &key (wear nil wear-p))
    (declare (ignorable wear))
    (format t "*~a gets up and runs to the bathroom*~%" (name-of user))
    (apply 'wet :wetter user :force-wet-amount t  :pants-down t (when wear-p `(:clothes ,wear))))
  (:method (user (checkpoint (eql :lose)) had-accident (amount (eql :some)) &key wear)
    (declare (ignore wear))
    (format t "*~a floods ~:[her~;his~] pamps*~%" (name-of user) (malep user)))
  (:method (user (checkpoint (eql :lose)) had-accident (amount (eql :all)) &key wear)
    (declare (ignore wear))
    (format t "*~a floods ~:[her~;his~] pamps*~%" (name-of user) (malep user)))
  (:method ((user player) checkpoint had-accident amount &key wear)
    (declare (ignore wear)))
  (:method ((user player) (checkpoint (eql :need-to-potty)) had-accident amount &key wear)
    (declare (ignore wear))
    (format t "*You need to pee*~%"))
  (:method ((user player) (checkpoint (eql :potty-dance)) had-accident amount &key wear)
    (declare (ignore wear))
    (format t "*You start doing a potty dance in your seat*~%")
    (when (typep (ai-of *application-frame*) 'yadfa-enemies:diapered-raccoon-bandit)
      (format t "~a: What's wrong? Baby gotta potty?.~%" (name-of (ai-of *application-frame*)))
      (format t "~a: Notta baby.~%" (name-of user))
      (format t "~a: Then try and keep your diapers dry.~%" (name-of (ai-of *application-frame*)))))
  (:method ((user player) (checkpoint (eql :potty-desparate)) had-accident amount &key wear)
    (declare (ignore wear))
    (format t "*You're doing a potty dance in your seat like a 5 year old struggling to keep your pampers dry*~%")
    (when (typep (ai-of *application-frame*) 'yadfa-enemies:diapered-raccoon-bandit)
      (format t "*~a watches in amusement.*~%" (name-of (ai-of *application-frame*)))))
  (:method ((user player) (checkpoint (eql :lose)) had-accident (amount (eql :dribble)) &key wear)
    (format t "*A little dribbles out into your diapers. The dribbles then turn into floods and you completely soak your padding*~%")
    (wet :wetter user :force-wet-amount t :clothes wear)
    (when (typep (ai-of *application-frame*) 'yadfa-enemies:diapered-raccoon-bandit)
      (format t "~a: Yep, baby.~%" (name-of (ai-of *application-frame*)))))
  (:method ((user player) (checkpoint (eql :lose)) had-accident (amount (eql :some)) &key wear)
    (format t "*You get a look of embarrassment on your face as you flood your pamps*~%")
    (wet :wetter user :force-wet-amount t :clothes wear)
    (when (typep (ai-of *application-frame*) 'yadfa-enemies:diapered-raccoon-bandit)
      (format t "~a: Aww, baby went potty.~%" (name-of (ai-of *application-frame*)))
      (format t "*the ~a gives his diaper a proud pat showing that ~:[she~;he~]'s still dry.*~%" (name-of (ai-of *application-frame*))
              (malep (ai-of *application-frame*)))
      (when (eq (getf *checkpoints* (ai-of *application-frame*)) :potty-desparate)
        (format t "~a's proud smile quickly turns into an expression of embarrassment.~%" (name-of (ai-of *application-frame*)))
        (format t "~a: Uh oh~%" (name-of (ai-of *application-frame*)))
        (format t "*~a rushes to the bathroom holding the front of ~:[her~;his~] diaper.*~%"
                (name-of (ai-of *application-frame*)) (malep (ai-of *application-frame*)))
        (format t "*After using the bathroom ~a looks at ~:[her~;his~] diaper and notices that ~:*~:[she~;he~] wet it a bit.*~%"
                (name-of (ai-of *application-frame*)) (malep (ai-of *application-frame*)))
        (format t "~a: Eh, close enough.~%" (name-of (ai-of *application-frame*)))
        (format t "*~a puts the damp diaper back on*~%" (name-of (ai-of *application-frame*)))))))
(declaim (type vector *player-cards* *ai-cards* *deck*)
         (type list *player-clothes*)
         (type (member :playing :end-game :end-round) *round*)
         (type boolean *put-on-old-clothes*))
(define-conditional-application-frame game-frame
    ()
  (:enable-commands (playing-commands)
   :disable-commands (end-game-commands end-round-commands))
  ((ai
    :initform nil
    :initarg :ai
    :accessor ai-of))
  (:command-table (game-frame :inherit-from (playing-commands end-game-commands end-round-commands)))
  (:pane (vertically ()
           (make-clim-stream-pane :name 'game :scroll-bars nil :incremental-redisplay t
                                  :display-time :command-loop :display-function 'draw-game :width 640 :height 200 :max-height 300)
           (make-clim-stream-pane :name 'gadgets :scroll-bars nil :incremental-redisplay nil :background climi::*3d-normal-color*
                                  :display-time :command-loop :display-function 'draw-gadgets :width 640 :max-height 80)
           (make-clim-interactor-pane :display-time :command-loop :name 'int :width 1200))))
(defmethod run-frame-top-level ((frame game-frame) &key)
  (let ((*player-cards* (make-array 12 :fill-pointer 0 :initial-element nil :element-type '(or null card)))
        (*ai-cards* (make-array 12 :fill-pointer 0 :initial-element nil :element-type '(or null card)))
        (*deck* (make-array 48 :fill-pointer 48 :element-type 'card :initial-contents (iter (for value in '(2 3 4 5 6 7 8 9 :king :queen :jack :ace))
                                                                                        (dolist (suit '(:diamond :club :heart :spade))
                                                                                          (collect (make-instance 'card :value value :suit suit))))))
        (*round* :playing)
        (*player-clothes* (list (make-instance 'yadfa-items:blackjack-uniform-diaper)))
        *checkpoints*
        *put-on-old-clothes*)
    (declare (special *player-cards* *player-clothes* *ai-cards* *checkpoints* *deck* *round*)
             (type vector *player-cards* *ai-cards* *deck*)
             (type list *player-clothes*)
             (type (member :playing :end-game :end-round) *round*)
             (type boolean *put-on-old-clothes*))
    (handler-case (call-next-method)
      (frame-exit ()
        (if *put-on-old-clothes*
            (push *player-clothes* (inventory-of (player-of *game*)))
            (progn
              (setf (inventory-of (player-of *game*)) (nconc (wear-of (player-of *game*)) (inventory-of (player-of *game*))))
              (setf (wear-of (player-of *game*)) *player-clothes*)))
        (eq (getf *checkpoints* (ai-of frame)) :lose)))))
(defmacro draw-bar (medium point stat &rest colors)
  `(multiple-value-bind (x y) (point-position ,point)
     (draw-rectangle* ,medium x y (+ x (* ,stat 400)) (+ y 15)
                      :ink (cond ,@(iter (for i in colors)
                                     (collect `(,(car i) ,(intern (format nil "+~a+"
                                                                          (if (typep (car (last i)) 'cons)
                                                                              (caar (last i))
                                                                              (car (last i))))
                                                                  "CLIM"))))))
     (draw-rectangle* ,medium x y (+ x 400) (+ y 15)
                      :filled nil)
     (setf (stream-cursor-position ,medium) (values (+ x 400) y))))
(defun deal ()
  (set-mode :playing)
  (iter (for i in-vector *player-cards*)
    (vector-push i *deck*))
  (iter (for i in-vector *ai-cards*)
    (vector-push i *deck*))
  (setf (fill-pointer *player-cards*) 0
        (fill-pointer *ai-cards*) 0)
  (setf *deck* (alexandria:shuffle *deck*))
  (vector-push (vector-pop *deck*) *player-cards*)
  (vector-push (vector-pop *deck*) *player-cards*)
  (vector-push (let ((a (vector-pop *deck*)))
                 (setf (side-of a) :down)
                 a)
               *ai-cards*)
  (vector-push (vector-pop *deck*) *ai-cards*))
(declaim (ftype (function (vector) fixnum) calculate-total))
(defun calculate-total (cards)
  (declare (type vector cards))
  (let ((ace nil)
        (total 0))
    (declare (type boolean ace)
             (type fixnum total))
    (iter (for i in-vector cards)
      (when i
        (typecase (value-of i)
          (fixnum (incf total (value-of i)))
          ((member :king :queen :jack) (incf total 10))
          ((eql :ace) (setf ace t) (incf total)))))
    (if (and ace (<= total 10))
        (+ total 10)
        total)))
(defun set-mode (key)
  (declare (type keyword key))
  (setf *round* key)
  (change-entity-enabledness (case *round*
                               (:playing 'com-playing-mode)
                               (:end-round 'com-end-round-mode)
                               (:end-game 'com-end-game-mode))))
(declaim (ftype (function (game-frame stream) (values symbol &optional list)) process-potty))
(defun process-potty (frame stream)
  (declare (type stream stream)
           (type game-frame frame)
           (ignore stream))
  (labels ((process-potty-checkpoint (user)
             (switch (user :test (lambda (o e)
                                   (>= (bladder/contents-of o) (funcall e o))))
               ('bladder/need-to-potty-limit-of :need-to-potty)
               ('bladder/potty-dance-limit-of :potty-dance)
               ('bladder/potty-desperate-limit-of :potty-desparate)
               ('bladder/maximum-limit-of :lose)))
           (process-potty-user (user &optional (clothing nil clothing-p))
             (let ((new-checkpoint (process-potty-checkpoint user))
                   (had-accident (when (>= (bladder/contents-of (player-of *game*)) (bladder/maximum-limit-of (player-of *game*)))
                                   (apply 'wet :wetter user :accident t (when clothing-p `(:clothes ,clothing))))))
               (unless (eq (getf *checkpoints* user) new-checkpoint)
                 (setf (getf *checkpoints* user) new-checkpoint)
                 (apply 'print-potty user new-checkpoint had-accident (getf had-accident :accident)
                        (when clothing-p
                          `(:clothes ,clothing)))
                 had-accident))))
    (macrolet ((thunk (&rest args)
                 `(let ((had-accident (process-potty-user ,@args)))
                    (when had-accident (return-from process-potty ,(car args))))))
      (thunk (player-of *game*) *player-clothes*)
      (thunk (ai-of frame)))))
(defmethod default-frame-top-level ((frame game-frame)
                                    &key command-parser
                                         command-unparser
                                         partial-command-parser
                                         prompt)
  (declare (ignore command-parser command-unparser partial-command-parser prompt))
  (deal)
  (call-next-method))
(define-command (com-hit :name t :command-table playing-commands)
    ()
  (vector-push (vector-pop *deck*) *player-cards*)
  (let ((total (calculate-total *player-cards*))
        (stream (frame-standard-output *application-frame*)))
    (format stream "~d~%" total)
    (when (> total 21)
      (incf (bladder/contents-of (player-of *game*)) 50)
      (write-line "bust" stream)
      (setf (side-of (aref *ai-cards* 0)) :up)
      (if (process-potty *application-frame* stream)
          (set-mode :end-game)
          (set-mode :end-round)))))
(define-command (com-exit-game :name t :command-table end-game-commands)
    ((put-on-old-clothes boolean :default nil :prompt "Put on old clothes?:"))
  (locally (declare (type boolean put-on-old-clothes))
    (setf *put-on-old-clothes* put-on-old-clothes)
    (frame-exit *application-frame*)))
(define-command (com-give-up :name t :command-table playing-commands)
    ((go-potty '(member-alist (("Run to the toilet" :toilet)
                               ("Flood your pamps" :pamps)))
               :default :pamps :prompt "[[Run to the toilet | Flood your pamps]]?: ")
     (put-on-old-clothes boolean :default nil :prompt "Put on old clothes?: "))
  (locally (declare (type boolean put-on-old-clothes)
                    (type keyword go-potty))
    (let ((pants-down (case go-potty
                        (:toilet t)
                        (:pants nil))))
      (declare (type boolean pants-down))
      (wet :pants-down pants-down :clothes *player-clothes*)
      (mess :pants-down pants-down :clothes *player-clothes*))
    (setf *put-on-old-clothes* put-on-old-clothes)
    (frame-exit *application-frame*)))
(defclass give-up () ())
(define-presentation-to-command-translator give-up-with-accept
    (give-up com-give-up game-frame
     :gesture :select
     :documentation "Give Up?"
     :pointer-documentation "Give Up?")
    (object frame)
  (let ((*query-io* (frame-query-io frame))
        go-potty put-on-old-clothes)
    (accepting-values (*query-io* :own-window t :exit-boxes '((:exit "Accept")))
      (fresh-line *query-io*)
      (setf go-potty (accept '(member-alist (("Run to the toilet" :toilet)
                                             ("Flood your pamps" :pamps)))
                             :prompt "[[Run to the toilet | Flood your pamps]]? "
                             :default :pamps :stream *query-io* :view +option-pane-view+))
      (fresh-line *query-io*)
      (setf put-on-old-clothes (accept 'boolean
                                       :prompt "Put on old clothes?:"
                                       :default t :stream *query-io* :view +toggle-button-view+)))
    `(,go-potty ,put-on-old-clothes)))
(define-command (com-stay :name t :command-table playing-commands)
    ()
  (let ((player-total (calculate-total *player-cards*))
        (stream (frame-standard-output *application-frame*)))
    (iter (while (<= player-total (calculate-total *ai-cards*) 20))
      (vector-push (vector-pop *deck*) *ai-cards*))
    (let ((ai-total (calculate-total *ai-cards*)))
      (cond
        ((> ai-total 21)
         (incf (bladder/contents-of (ai-of *application-frame*)) 50)
         (format stream "~a bust~%" (name-of (ai-of *application-frame*))))
        ((> ai-total player-total)
         (incf (bladder/contents-of (player-of *game*)) 50)
         (format stream "~a win~%" (name-of (ai-of *application-frame*))))
        ((eql ai-total player-total)
         (write-line "tie" stream))
        (t
         (incf (bladder/contents-of (ai-of *application-frame*)) 50)
         (format stream "~a win~%" (name-of (player-of *game*))))))
    (setf (side-of (aref *ai-cards* 0)) :up)
    (if (process-potty *application-frame* stream)
        (set-mode :end-game)
        (set-mode :end-round))))
(define-command (com-next-round :name t :command-table end-round-commands)
    ()
  (deal)
  (set-mode :playing))
(define-command (com-clear-history :name t :command-table game-commands)
    ()
  (window-clear (frame-standard-output *application-frame*)))
(define-conditional-command (com-playing-mode)
    (game-frame :enable-commands (playing-commands)
                :disable-commands (end-round-commands end-game-commands))
    ())
(define-conditional-command (com-end-round-mode)
    (game-frame :enable-commands (end-round-commands)
                :disable-commands (playing-commands end-game-commands))
    ())
(define-conditional-command (com-end-game-mode)
    (game-frame :enable-commands (end-game-commands)
                :disable-commands (playing-commands end-round-commands))
    ())
(defclass stat-view (view) ())
(defconstant +stat-view+ (make-instance 'stat-view))
(define-presentation-method present (user (type base-character) medium (view stat-view) &key)
  (format medium "Name: ~a~%" (name-of user))
  (format medium "Bladder: ")
  (yadfa-clim:draw-bar medium
                       (/ (bladder/contents-of user) (bladder/maximum-limit-of user))
                       ((>= (bladder/contents-of user) (bladder/potty-desperate-limit-of user)) :red)
                       ((>= (bladder/contents-of user) (bladder/potty-dance-limit-of user)) (:orange :red))
                       ((>= (bladder/contents-of user) (bladder/need-to-potty-limit-of user)) :yellow)
                       (t :green))
  (terpri medium))
(defun draw-game (frame pane)
  (declare (type game-frame frame)
           (type clim-stream-pane pane))
  (labels ((draw-heart (point)
             (declare (type point point))
             (draw-circle* pane (+ (point-x point) 10) (+ (point-y point) 10) 10 :ink +red+)
             (draw-circle* pane (+ (point-x point) 30) (+ (point-y point) 10) 10 :ink +red+ )
             (draw-polygon pane (iter (for (x y) on '(0 10 40 10 20 40) by 'cddr)
                                  (collect (make-point (+ (point-x point) x) (+ (point-y point) y)))) :ink +red+))
           (draw-spade (point)
             (declare (type point point))
             (draw-circle* pane (+ (point-x point) 10) (+ (point-y point) 20) 10 :ink +black+)
             (draw-circle* pane (+ (point-x point) 30) (+ (point-y point) 20) 10 :ink +black+)
             (draw-polygon pane (iter (for (x y) on '(0 15 20 0 40 15 20 20) by 'cddr)
                                  (collect (make-point (+ (point-x point) x) (+ (point-y point) y)))) :ink +black+)
             (draw-polygon pane (iter (for (x y) on '(10 40 30 40 20 20) by 'cddr)
                                  (collect (make-point (+ (point-x point) x) (+ (point-y point) y)))) :ink +black+))
           (draw-diamond (point)
             (declare (type point point))
             (draw-polygon pane (iter (for (x y) on '(20 0 0 20 20 40 40 20) by 'cddr)
                                  (collect (make-point (+ (point-x point) x) (+ (point-y point) y)))) :ink +red+))
           (draw-club (point)
             (declare (type point point))
             (draw-circle* pane (+ (point-x point) 10) (+ (point-y point) 20) 10 :ink +black+)
             (draw-circle* pane (+ (point-x point) 30) (+ (point-y point) 20) 10 :ink +black+)
             (draw-circle* pane (+ (point-x point) 20) (+ (point-y point) 10) 10 :ink +black+)
             (draw-polygon pane (iter (for (x y) on '(10 40 30 40 20 20) by 'cddr)
                                  (collect (make-point (+ (point-x point) x) (+ (point-y point) y)))) :ink +black+))
           (draw-card (card point)
             (declare (type card card)
                      (type point point))
             (case (side-of card)
               (:down (draw-rectangle pane point (make-point (+ (point-x point) 40) (+ (point-y point) 40))
                                      :ink *back-card-pattern*))
               (:up (let ((text (typecase (value-of card)
                                  (fixnum (write-to-string (value-of card)))
                                  ((eql :king) "K")
                                  ((eql :queen) "Q")
                                  ((eql :jack) "J")
                                  ((eql :ace) "A")
                                  (t ""))))
                      (case (suit-of card)
                        (:diamond (draw-diamond point))
                        (:spade (draw-spade point))
                        (:club (draw-club point))
                        (:heart (draw-heart point)))
                      (draw-text* pane text (+ (point-x point) 20) (+ (point-y point) 20) :ink +white+ :align-x :center :align-y :center)))))
           (draw-row (user cards)
             (declare (type vector cards)
                      (type base-character user))
             (multiple-value-bind (x y) (stream-cursor-position pane)
               (declare (ignore x))
               (iter (for i in-vector cards)
                 (for x upfrom 0)
                 (updating-output (pane :unique-id `(,user ,x) :id-test 'equal :cache-value `(,i ,(side-of i)) :cache-test 'equal)
                   (draw-card i (make-point (+ (* x 40) 10) y))))
               (stream-increment-cursor-position pane 0 40)
               (updating-output (pane :unique-id user :id-test 'eq :cache-value (bladder/contents-of user))
                 (present user 'base-character :view +stat-view+ :stream pane)))))
    (setf (stream-cursor-position pane) (values 0 0))
    (draw-row (ai-of frame) *ai-cards*)
    (draw-row (player-of *game*) *player-cards*)))
(defun draw-gadgets (frame pane)
  (declare (ignore frame))
  (formatting-item-list (pane)
    (let ((table (case *round*
                   (:playing 'playing-commands)
                   (:end-round 'end-round-commands)
                   (:end-game 'end-game-commands))))
      (macrolet ((thunk (&rest alist)
                   `(map-over-command-table-names
                     (lambda (name symbol)
                       (formatting-cell (pane)
                         (case symbol
                           ,@(iter (for i in (append alist '((t `(,(gadget-client button)) (command :command-table game-frame)))))
                               (destructuring-bind (command object type) i
                                 (collect `(,command (with-output-as-gadget (pane)
                                                       (make-pane 'push-button
                                                                  :label name
                                                                  :client symbol
                                                                  :activate-callback
                                                                  (lambda (button)
                                                                    (declare (ignorable button))
                                                                    ;; apparently panes don't work as presentations in McCLIM
                                                                    (throw-highlighted-presentation
                                                                     (make-instance 'standard-presentation
                                                                                    :object ,object
                                                                                    :single-box t
                                                                                    :type ',type)
                                                                     *input-context*
                                                                     (make-instance 'pointer-button-press-event
                                                                                    :sheet nil
                                                                                    :x 0 :y 0
                                                                                    :modifier-state 0
                                                                                    :button +pointer-left-button+))))))))))))
                     table
                     :inherited nil)))
        (thunk ('com-give-up (make-instance 'give-up) give-up))))))
(defun run-game (&optional (enemy 'enemy))
  (let ((*default-server-path* (if (eq (car (clim:port-server-path (clim:find-port))) :clx-ff)
                                   :clx-ttf nil))
        (*default-text-style* (make-text-style :fix :roman :normal))) ;; https://github.com/McCLIM/McCLIM/issues/913
    (declare (special *default-server-path* *default-text-style*))
    (run-frame-top-level (make-application-frame 'game-frame
                                                 :pretty-name "Blackjack"
                                                 :ai (make-instance enemy :wear (list (make-instance 'yadfa-items:blackjack-uniform-diaper)))))))
