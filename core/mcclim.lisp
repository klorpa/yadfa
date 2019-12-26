;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa-clim"; coding: utf-8-unix; -*-
(in-package :yadfa-clim)
(define-command-table yadfa-world-commands)
(define-command-table yadfa-battle-commands)
(define-command-table yadfa-bin-commands)
(define-command-table yadfa-menu-commands)
(define-command-table application-commands)
(define-command (com-clear-output :name "Clear Output History"
                                  :command-table application-commands
                                  :menu t
                                  :provide-output-destination-keyword nil)
    ()
  (window-clear *standard-output*)
  (setf *records* nil))
(map-over-command-table-names (lambda (name command)
                                (unless (eq command 'clim-listener::com-clear-output)
                                  (add-command-to-command-table command (find-command-table 'application-commands) :errorp nil)
                                  (add-menu-item-to-command-table (find-command-table 'application-commands) name :command command :errorp nil)))
                              (find-command-table 'clim-listener::application-commands)
                              :inherited nil)
(define-conditional-application-frame yadfa-listener (clim-listener::listener)
  (:enable-commands '(yadfa-bin-commands yadfa-world-commands)
   :disable-commands '(yadfa-world-commands))
  ()
  (:panes (clim-listener::interactor-container
           (make-clim-stream-pane
            :type 'clim-listener::listener-interactor-pane
            :name 'clim-listener::interactor :scroll-bars t
            :default-view clim-listener::+listener-view+
            :end-of-line-action :wrap*))
          (clim-listener::doc :pointer-documentation :default-view clim-listener::+listener-pointer-documentation-view+)
          (clim-listener::wholine (make-pane 'clim-listener::wholine-pane
                                             :display-function 'clim-listener::display-wholine :scroll-bars nil
                                             :display-time :command-loop :end-of-line-action :allow)))
  (:top-level (default-frame-top-level :prompt 'clim-listener::print-listener-prompt))
  (:command-table (yadfa-listener
                   :inherit-from (
                                  clim-listener::listener
                                  yadfa-menu-commands
                                  yadfa-world-commands
                                  yadfa-battle-commands
                                  yadfa-bin-commands
                                  application-commands)
                   :menu (("Listener"   :menu application-commands)
                          ("Lisp"       :menu clim-listener::lisp-commands)
                          ("Filesystem" :menu clim-listener::filesystem-commands)
                          ("Show"       :menu clim-listener::show-commands)
                          ("Yadfa"      :menu yadfa-menu-commands))))
  (:disabled-commands clim-listener::com-clear-output)
  (:menu-bar t)
  (:layouts (default
             (vertically ()
               clim-listener::interactor-container
               clim-listener::doc
               clim-listener::wholine))))
(define-command (yadfa-set-eol-action :command-table yadfa-menu-commands :menu "Set EOL Action")
    ((keyword '(member :scroll :allow :wrap :wrap*)
              :prompt "Keyword"))
  (setf (stream-end-of-line-action *query-io*) keyword))
(define-command (yadfa-gc :command-table yadfa-menu-commands :menu "GC")
    ()
  (trivial-garbage:gc :full t))
(define-conditional-command (com-enable-world)
    (yadfa-listener :enable-commands (yadfa-world-commands yadfa-bin-commands)
                    :disable-commands (yadfa-battle-commands))
    ())
(define-conditional-command (com-enable-battle)
    (yadfa-listener :enable-commands (yadfa-battle-commands yadfa-bin-commands)
                    :disable-commands (yadfa-world-commands))
    ())
(define-command
    (com-inspect :command-table global-command-table :name "Inspect")
    ((obj 'expression
          :prompt "object"
          :gesture :inspect))
  (clouseau:inspect obj :new-process t))
(defclass stat-view (view) ())
(defconstant +stat-view+ (make-instance 'stat-view))
(defmacro draw-bar (medium stat &rest colors)
  `(multiple-value-bind (x y) (stream-cursor-position ,medium)
     (draw-rectangle* ,medium x y (+ x (* ,stat 400)) (+ y 15)
                      :ink (cond ,@(iter (for i in colors)
                                     (collect `(,(car i) ,(intern (format nil "+~a+"
                                                                          (if (typep (car (last i)) 'cons)
                                                                              (caar (last i))
                                                                              (car (last i))))
                                                                  "CLIM"))))))
     (draw-rectangle* ,medium x y (+ x 400) (+ y 15)
                      :filled nil)
     (stream-set-cursor-position ,medium (+ x 400) y)))
(define-presentation-method present (object (type base-character) stream (view stat-view) &key)
  (format stream "Name: ~a~%" (name-of object))
  (format stream "Sex: ~a~%" (if (malep object) "Male" "Female"))
  (format stream "Species: ~a~%" (species-of object))
  (format stream "Description: ~a~%" (description-of object))
  (when (typep object 'team-member)
    (format stream "Tail: ~a~%" (tail-of object))
    (format stream "Wings: ~a~%" (wings-of object))
    (format stream "Skin: ~a~%" (skin-of object)))
  (format stream "Health: ")
  (draw-bar stream (/ (health-of object) (calculate-stat object :health))
            ((> (health-of object) (* (calculate-stat object :health) 1/2)) :green)
            ((> (health-of object) (* (calculate-stat object :health) 1/4)) :yellow)
            (t :red))
  (format stream " ~a~%Energy: "
          (if (member object (cons (player-of *game*) (allies-of *game*)))
              (format nil "(~a/~a)"
                      (health-of object)
                      (calculate-stat object :health))
              ""))
  (draw-bar stream (/ (energy-of object) (calculate-stat object :energy))
            ((> (energy-of object) (* (calculate-stat object :energy) 1/2)) :green)
            ((> (energy-of object) (* (calculate-stat object :energy) 1/4)) :yellow)
            (t :red))
  (format stream " ~a~%"
          (if (member object (cons (player-of *game*) (allies-of *game*)))
              (format nil "(~a/~a)"
                      (energy-of object)
                      (calculate-stat object :energy))
              ""))
  (when *battle*
    (write-string "Conditions: " stream)
    (iter (for i in (getf (status-conditions-of *battle*) object))
      (format stream "`~a' " (name-of i)))
    (write-char #\Newline stream))
  (format stream "Stats: ~a~%Base-Stats: ~a~%"
          (let ((wield-stats (calculate-wield-stats object))
                (wear-stats (calculate-wear-stats object)))
            (iter (for (a b) on (base-stats-of object) by #'cddr)
              (collect a)
              (collect (+ b (getf wield-stats a) (getf wear-stats a)))))
          (base-stats-of object))
  (let ((c (filter-items (wear-of object) 'closed-bottoms)))
    (destructuring-bind (&key (sogginess 0) (sogginess-capacity 0) (messiness 0) (messiness-capacity 0)) c
      (declare (type real sogginess sogginess-capacity messiness messiness-capacity))
      (cond ((find '(or tabbed-briefs pullon incontinence-pad) c :test (lambda (o e) (typep e o)))
             (format stream "Diaper State: ~{~a~}~%"
                     (let ((a ()))
                       (cond ((>= sogginess sogginess-capacity)
                              (push "Leaking" a)
                              (push " " a))
                             ((>= sogginess 100)
                              (push "Soggy" a)
                              (push " " a)))
                       (cond ((>= messiness messiness-capacity)
                              (push "Blowout" a))
                             ((>= messiness 100)
                              (push "Messy" a)))
                       (unless a (push "Clean" a))
                       a)))
            (c
             (format stream "Pants State: ~{~a~}~%"
                     (let ((a ()))
                       (cond ((>= sogginess sogginess-capacity)
                              (push "Wet" a)
                              (push " " a)))
                       (cond ((>= messiness messiness-capacity)
                              (push "Messy" a)))
                       (unless a (push "Clean" a))
                       a))))
      (when c
        (write-string "Sogginess: " stream)
        (draw-bar stream (/ sogginess sogginess-capacity)
                  ((>= sogginess (- sogginess-capacity (/ sogginess-capacity 4))) :red)
                  ((>= sogginess (/ sogginess-capacity 2)) :yellow)
                  (t :green))
        (terpri stream)
        (write-string "Messiness: " stream)
        (draw-bar stream (/ messiness messiness-capacity)
                  ((>= messiness (- messiness-capacity (/ messiness-capacity 4))) :red)
                  ((>= messiness (/ messiness-capacity 2)) :yellow)
                  (t :green))
        (terpri stream))))
  (write-string "Bladder State: " stream)
  (draw-bar stream (/ (bladder/contents-of object) (bladder/maximum-limit-of object))
            ((>= (bladder/contents-of object) (bladder/potty-desperate-limit-of object)) :red)
            ((>= (bladder/contents-of object) (bladder/potty-dance-limit-of object)) (:orange :red))
            ((>= (bladder/contents-of object) (bladder/need-to-potty-limit-of object)) :yellow)
            (t :green))
  (terpri stream)
  (write-string "Bowels State: " stream)
  (draw-bar stream (/ (bowels/contents-of object) (bowels/maximum-limit-of object))
            ((>= (bowels/contents-of object) (bowels/potty-desperate-limit-of object)) :red)
            ((>= (bowels/contents-of object) (bowels/potty-dance-limit-of object)) (:orange :red))
            ((>= (bowels/contents-of object) (bowels/need-to-potty-limit-of object)) :yellow)
            (t :green))
  (terpri stream))
(define-command (com-yadfa-move :command-table yadfa-world-commands :menu t :name "Move")
    ((zone '(or zone form)))
  (cond ((typep zone 'zone)
         (block nil
           (apply #'yadfa-world:move
                  (destructuring-bind (new-x new-y new-z new-zone) (position-of zone)
                    (destructuring-bind (old-x old-y old-z old-zone) (position-of (player-of *game*))
                      (cond
                        (*battle*
                         (format t "You can't do this in battle~%")
                         (return))
                        ((and (< old-x new-x) (= old-y new-y) (= old-z new-z) (equal old-zone new-zone))
                         (iter (for i from (1+ old-x) to new-x)
                           (collect :east)))
                        ((and (> old-x new-x) (= old-y new-y) (= old-z new-z) (equal old-zone new-zone))
                         (iter (for i from (1- old-x) downto new-x)
                           (collect :west)))
                        ((and (= old-x new-x) (< old-y new-y) (= old-z new-z) (equal old-zone new-zone))
                         (iter (for i from (1+ old-y) to new-y)
                           (collect :south)))
                        ((and (= old-x new-x) (> old-y new-y) (= old-z new-z) (equal old-zone new-zone))
                         (iter (for i from (1- old-y) downto new-y)
                           (collect :north)))
                        (t
                         (format t "You're either already on that zone or you tried specifying a path that involves turning (which this interface can't do because Pouar sucks at writing code that generates paths)~%")
                         (return))))))))
        (t
         (apply 'yadfa-world:move zone))))
(define-command (com-yadfa-describe-zone :command-table yadfa-bin-commands :menu t :name "Describe Zone")
    ((zone zone))
  (yadfa-bin:lst :describe-zone zone))
(define-presentation-to-command-translator com-yadfa-move-translator
    (zone com-yadfa-move yadfa-world-commands
     :documentation "Move"
     :pointer-documentation "Move Here"
     :gesture nil
     :menu t
     :tester ((object) (destructuring-bind (new-x new-y new-z new-zone) (position-of object)
                         (destructuring-bind (old-x old-y old-z old-zone) (position-of (player-of *game*))
                           (and (= old-z new-z) (equal old-zone new-zone) (or (and (= old-y new-y) (/= old-x new-x))
                                                                              (and (= old-x new-x) (/= old-y new-y))))))))
    (object)
  (list object))
(define-presentation-to-command-translator com-yadfa-move-translator-up
    (zone com-yadfa-move yadfa-world-commands
     :documentation "Move Up"
     :pointer-documentation "Move Up"
     :gesture nil
     :menu t
     :tester ((object) (and (equal (position-of (player-of *game*)) (position-of object))
                            (get-zone (destructuring-bind (x y z zone) (position-of object)
                                        `(,x ,y ,(1+ z) ,zone)))
                            (yadfa::travelablep (position-of (player-of *game*)) :up))))
    (object)
  '((:up)))
(define-presentation-to-command-translator com-yadfa-move-translator-down
    (zone com-yadfa-move yadfa-world-commands
     :documentation "Move Down"
     :pointer-documentation "Move Down"
     :gesture nil
     :menu t
     :tester ((object) (and (equal (position-of (player-of *game*)) (position-of object))
                            (get-zone (destructuring-bind (x y z zone) (position-of object)
                                        `(,x ,y ,(1- z) ,zone)))
                            (yadfa::travelablep (position-of (player-of *game*)) :down))))
    (object)
  '((:down)))
(define-presentation-to-command-translator com-yadfa-move-translator-warp
    (zone com-yadfa-move yadfa-world-commands
     :documentation "Move To Waypoint"
     :pointer-documentation "Move To Waypoint"
     :gesture nil
     :menu t
     :tester ((object) (and (equal (position-of (player-of *game*)) (position-of object))
                            (iter (for (point position) on (warp-points-of (get-zone (position-of object))) by 'cddr)
                              (unless (yadfa::travelablep (position-of (player-of *game*)) point)
                                (collect point))))))
    (object)
  `((,(let ((*query-io* (frame-query-io (find-application-frame 'yadfa-listener))))
        (accepting-values (*query-io* :resynchronize-every-pass t)
          (accept `(member-alist ,(iter (for (key position) on (warp-points-of (get-zone (position-of object))) by 'cddr)
                                    (unless (yadfa::travelablep (position-of (player-of *game*)) key)
                                      (collect (cons (write-to-string key) key))))) :view clim:+radio-box-view+ :stream *query-io*))))))
(define-presentation-to-command-translator com-yadfa-describe-zone-translator
    (zone com-yadfa-describe-zone yadfa-bin-commands
     :documentation "Describe Zone"
     :pointer-documentation "Print Zone Description"
     :gesture nil
     :menu t)
    (object)
  (list object))
(define-application-frame emacs-frame (standard-application-frame)
  ((lambda :accessor emacs-frame-lambda
     :initarg :emacs-frame-lambda
     :initform (lambda (frame)
                 (declare (ignore frame))
                 t)))
  (:panes (int :interactor :height 400 :width 600))
  (:layouts
   (default int)))
(defmethod default-frame-top-level :around ((frame emacs-frame)
                                            &key (command-parser 'command-line-command-parser)
                                                 (command-unparser 'command-line-command-unparser)
                                                 (partial-command-parser
                                                  'command-line-read-remaining-arguments-for-partial-command)
                                                 (prompt "Command: "))
  (declare (ignore prompt))
  (let* ((frame-query-io (frame-query-io frame))
         (interactorp (typep frame-query-io 'interactor-pane))
         (*standard-input*  (or (frame-standard-input frame)  *standard-input*))
         (*standard-output* (or (frame-standard-output frame) *standard-output*))
         (*query-io* (or frame-query-io *query-io*))
         ;; during development, don't alter *error-output*
         ;; (*error-output* (frame-error-output frame))
         (*pointer-documentation-output* (frame-pointer-documentation-output frame))
         (*command-parser* command-parser)
         (*command-unparser* command-unparser)
         (*partial-command-parser* partial-command-parser))
    (restart-case
        (progn
          (redisplay-frame-panes frame :force-p t)
          (when interactorp
            (setf (cursor-visibility (stream-text-cursor frame-query-io)) nil))
          (funcall (emacs-frame-lambda frame) frame))
      (abort ()
        :report "Return to application command loop."
        (if interactorp
            (format frame-query-io "~&Command aborted.~&")
            (beep))))))
;;; add init function
(defmethod default-frame-top-level
    ((frame yadfa-listener)
     &key (command-parser 'command-line-command-parser)
          (command-unparser 'command-line-command-unparser)
          (partial-command-parser
           'command-line-read-remaining-arguments-for-partial-command)
          (prompt "Command: "))
  ;; Give each pane a fresh start first time through.
  (let ((needs-redisplay t)
        (first-time t))
    (loop
      ;; The variables are rebound each time through the loop because the
      ;; values of frame-standard-input et al. might be changed by a command.
      ;;
      ;; We rebind *QUERY-IO* ensuring variable is always a stream,
      ;; but we use FRAME-QUERY-IO for our own actions and to decide
      ;; whenever frame has the query IO stream associated with it..
      (let* ((frame-query-io (frame-query-io frame))
             (interactorp (typep frame-query-io 'interactor-pane))
             (*standard-input*  (or (frame-standard-input frame)  *standard-input*))
             (*standard-output* (or (frame-standard-output frame) *standard-output*))
             (*query-io* (or frame-query-io *query-io*))
             ;; during development, don't alter *error-output*
             ;; (*error-output* (frame-error-output frame))
             (*pointer-documentation-output* (frame-pointer-documentation-output frame))
             (*command-parser* command-parser)
             (*command-unparser* command-unparser)
             (*partial-command-parser* partial-command-parser))
        (restart-case
            (flet ((execute-command ()
                     (alexandria:when-let ((command (read-frame-command frame :stream frame-query-io)))
                       (setq needs-redisplay t)
                       (serapeum:run-hooks 'yadfa:*cheat-hooks*)
                       (execute-frame-command frame command))))
              (when needs-redisplay
                (dolist (i yadfa-clim::*records*) do (redisplay i *standard-output*))
                (redisplay-frame-panes frame :force-p first-time)
                (when first-time
                  (yadfa::switch-user-packages)
                  (yadfa:intro-function))
                (setq first-time nil needs-redisplay nil)
                (when (>= (yadfa:time-of yadfa:*game*) (+ yadfa::*last-rng-update* 20))
                  (setf cl:*random-state* (make-random-state t)
                        yadfa::*last-rng-update* (yadfa:time-of yadfa:*game*))))
              (when interactorp
                (setf (cursor-visibility (stream-text-cursor frame-query-io)) nil)
                (when prompt
                  (with-text-style (frame-query-io climi::+default-prompt-style+)
                    (if (stringp prompt)
                        (write-string prompt frame-query-io)
                        (funcall prompt frame-query-io frame))
                    (force-output frame-query-io))))
              (execute-command)
              (when interactorp
                (fresh-line frame-query-io)))
          (abort ()
            :report "Return to application command loop."
            (if interactorp
                (format frame-query-io "~&Command aborted.~&")
                (beep))))))))
(define-condition emm386-memory-manager-error (serious-condition) ()
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-line "Thank you for playing Wing Commander!" stream))))
(defmethod frame-exit ((frame yadfa-listener))
  (unwind-protect (error 'emm386-memory-manager-error)
    (call-next-method)))
(defun run-listener (&key (new-process nil)
                          (debugger t)
                          (width 1024)
                          (height 1024)
                          port
                          frame-manager
                          (process-name "Yadfa")
                          (package :yadfa-user))
  (let* ((fm (or frame-manager (find-frame-manager :port (or port (find-port)))))
         (frame (make-application-frame 'yadfa-listener
                                        :frame-manager fm
                                        :width width
                                        :height height)))
    (flet ((run ()
             (let ((*package* (find-package package)))
               (unwind-protect
                    (if debugger
                        (clim-debugger:with-debugger () (run-frame-top-level frame))
                        (run-frame-top-level frame))
                 (disown-frame fm frame)))))
      (if new-process
          (values (bt:make-thread 'run :name process-name)
                  frame)
          (run)))))
