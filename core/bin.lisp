;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa"; coding: utf-8-unix; -*-
;;;;this file contains functions the player can enter in the REPL

(in-package :yadfa)
(defunassert yadfa-bin:get-inventory-of-type (type)
    (type type-specifier)
  (get-positions-of-type type (inventory-of (player-of *game*))))
(defun yadfa-bin:reload-files (&rest keys &key compiler-verbose &allow-other-keys)
  "Intended for developers. Use this to recompile the game without having to close it. Accepts the same keyword arguments as @code{ASDF:LOAD-SYSTEM} and @code{ASDF:OPERATE}. Set @var{COMPILER-VERBOSE} to @code{T} to print the compiling messages. setting @var{LOAD-SOURCE} to @code{T} will avoid creating fasls"
  (let ((*compile-verbose* compiler-verbose) (*compile-print* compiler-verbose))
    (apply #'asdf:load-system :yadfa :allow-other-keys t keys)
    (apply #'load-mods :allow-other-keys t keys))
  (switch-user-packages))
(defun yadfa-bin:enable-mods (systems)
  #.(format nil "Enable a mod, the modding system is mostly just asdf, @var{SYSTEM} is a keyword which is the name of the system you want to enable

~a."
            (xref yadfa-bin:disable-mods :function))
  (let ((systems (iter (for i in (a:ensure-list systems))
                   (collect (asdf:coerce-name i)))))
    (dolist (system (remove-duplicates systems :test #'string=))
      (asdf:find-system system))
    (dolist (system systems)
      (pushnew system *mods* :test #'string=)
      (asdf:load-system system))
    (a:with-output-to-file (stream #P"yadfa:config;mods.conf"
                                   :if-exists :supersede
                                   :external-format :utf-8)
      (write *mods* :stream stream)))
  systems)
(defun yadfa-bin:disable-mods (systems)
  #.(format nil "Disable a mod, the modding system is mostly just asdf, @var{SYSTEM} is a keyword which is the name of the system you want to enable

~a."
            (xref yadfa-bin:enable-mods :function))
  (let ((systems (delete-duplicates (iter (for i in (a:ensure-list systems))
                                      (collect (asdf:coerce-name i)))
                                    :test #'string=)))
    (a:deletef *mods* systems :test (lambda (o e)
                                      (member e o :test #'string=)))
    (a:with-output-to-file (stream #P"yadfa:config;mods.conf"
                                   :if-exists :supersede
                                   :external-format :utf-8)
      (write *mods* :stream stream)))
  systems)
(defunassert yadfa-world:save-game (path)
    (path (or simple-string pathname))
  #.(format nil "This function saves current game to @var{PATH}

~a."
            (xref yadfa-world:load-game :function))
  (ensure-directories-exist (make-pathname :host (pathname-host path) :device (pathname-device path) :directory (pathname-directory path)))
  (a:with-output-to-file (s path :if-exists :supersede :external-format :utf-8)
    (write-string (write-to-string (ms:marshal *game*)) s))
  (typecase path
    (logical-pathname (translate-logical-pathname path))
    (pathname path)
    (simple-string (handler-case (translate-logical-pathname path)
                     (type-error () (parse-namestring path))
                     (file-error () nil)))))
(defunassert yadfa-world:load-game (path)
    (path (or simple-string pathname))
  #.(format nil "This function loads a saved game from @var{PATH}

~a."
            (xref yadfa-world:save-game :function))
  (a:with-input-from-file (stream path)
    (setf *game* (ms:unmarshal (read stream))))
  (typecase path
    (logical-pathname (translate-logical-pathname path))
    (pathname path)
    (simple-string (handler-case (translate-logical-pathname path)
                     (type-error () (parse-namestring path))
                     (file-error () nil)))))
(defunassert yadfa-bin:toggle-onesie (&key wear user)
    (wear (or type-specifier unsigned-byte null) user (or type-specifier  unsigned-byte null))
  "Open or closes your onesie. @var{WEAR} is the index of a onesie. Leave @code{NIL} for the outermost onesie. @var{USER} is the index of an ally. Leave @code{NIL} to refer to yourself"
  (handle-user-input ((allies-length (list-length (allies-of *game*)))
                      (inventory-length (list-length (wear-of (player-of *game*))))
                      (selected-user (if user (if (numberp user)
                                                  (nth user (allies-of *game*))
                                                  (find user (allies-of *game*) :test (lambda (o e)
                                                                                        (typep e o))))
                                         (player-of *game*)))
                      (selected-wear (when wear (if (numberp wear)
                                                    (nthcdr wear (wear-of (player-of *game*)))
                                                    (member wear (wear-of (player-of *game*)) :test (lambda (o e)
                                                                                                      (typep e o)))))))
      (*query-io* ((and user (numberp user) (>= user allies-length))
                   (user)
                   :prompt-text "Enter a different ally"
                   :error-text (format nil "You only have ~d allies" allies-length))
                  ((and user (typep user 'type-specifier) (not selected-user))
                   (user)
                   :prompt-text "Enter a different ally"
                   :error-text (format nil "Ally ~s doesn't exist" user))
                  ((and wear (numberp wear) (>= wear inventory-length))
                   (wear)
                   :prompt-text "Select a different clothing"
                   :error-text (format nil "You're only wearing ~a items" inventory-length))
                  ((and wear (typep wear 'type-specifier) (not selected-wear))
                   (wear)
                   :prompt-text "Select a different clothing"
                   :error-text (format nil "You're not wearing that item"))
                  ((let ((selected-wear (if wear
                                            selected-wear
                                            (iter (for item on (wear-of selected-user))
                                              (when (typep (car item) 'onesie)
                                                (leave item))
                                              (finally (format t "~a isn't wearing a onesie"
                                                               (name-of selected-user)))))))
                     (handler-case (progn (toggle-onesie (car selected-wear) selected-wear selected-user)
                                          (let* ((male (malep selected-user))
                                                 (hisher (if male "his" "her"))
                                                 (onesie (car selected-wear)))
                                            (if (typep (car selected-wear) 'onesie/closed)
                                                (format t "~a snaps ~a ~a~%~%"
                                                        (name-of selected-user)
                                                        hisher
                                                        (name-of onesie))
                                                (format t "~a unsnaps ~a ~a~%~%"
                                                        (name-of selected-user)
                                                        hisher
                                                        (name-of onesie)))))
                       (onesie-too-thick (c)
                         (let* ((user (user-of c))
                                (clothes (clothes-of c))
                                (male (malep user))
                                (hisher (if male "his" "her")))
                           (format t "~a struggles to snap the bottom of ~a ~a like a toddler who can't dress ~aself but ~a ~a is too thick~%~%"
                                   (name-of user)
                                   hisher
                                   (name-of (car clothes))
                                   (if male "him" "her")
                                   hisher
                                   (name-of (thickest (cdr clothes))))))
                       (onesie-locked (c)
                         (let ((user (user-of c)))
                           (format t "~a can't unsnap ~a ~a as it's locked~%~%"
                                   (name-of user)
                                   (if (malep user) "his" "her")
                                   (name-of (car (clothes-of c)))))))
                     nil)
                   (wear)
                   :prompt-text "Select a different clothing"))))
(defunassert yadfa-world:move (&rest directions)
    (directions list)
  #.(format nil "type in the direction as a keyword to move in that direction, valid directions can be found with @code{(lst :directions t)}.
You can also specify multiple directions, for example @code{(move :south :south)} will move 2 zones south. @code{(move :south :west :south)} will move south, then west, then south.

~a."
            (xref yadfa-bin:lst :function))
  (iter (for direction in directions)
    (multiple-value-bind (new-position error) (get-path-end (get-destination direction (position-of (player-of *game*))) (position-of (player-of *game*)) direction)
      (let* ((old-position (position-of (player-of *game*))))
        (unless new-position
          (format t "~a" error)
          (return-from yadfa-world:move))
        (move-to-zone new-position :direction direction :old-position old-position)))))
(defunassert yadfa-bin:lst (&key inventory inventory-group props wear user directions moves position map descriptions describe-zone)
    (user (or unsigned-byte boolean)
          map (or boolean integer)
          inventory type-specifier)
  "used to list various objects and properties, @var{INVENTORY} takes a type specifier for the items you want to list in your inventory. setting @var{INVENTORY} to @code{T} will list all the items. @var{INVENTORY-GROUP} is similar to @var{INVENTORY}, but will group the items by class name. @var{WEAR} is similar to @var{INVENTORY} but lists clothes you're wearing instead. setting @var{DIRECTIONS} to non-NIL will list the directions you can walk.setting @var{MOVES} to non-NIL will list the moves you know. setting @var{USER} to @code{T} will cause @var{MOVES} and @var{WEAR} to apply to the player, setting it to an integer will cause it to apply it to an ally. Leaving it at @code{NIL} will cause it to apply to everyone. setting @var{POSITION} to true will print your current position. Setting @var{MAP} to a number will print the map with the floor number set to @var{MAP}, setting @var{MAP} to @code{T} will print the map of the current floor you're on. When printing the map in McCLIM, red means there's a warp point, dark green is the zone with the player, blue means there are stairs. These 3 colors will blend with each other to make the final color"
  (let ((allies-length (list-length (allies-of *game*))))
    (labels ((format-table (header &rest body)
               (c:formatting-table (t :x-spacing 20)
                 (c:with-text-style (*query-io* (c:make-text-style nil :bold nil))
                   (c:formatting-row ()
                     (iter (for cell in header)
                       (c:formatting-cell ()
                         (typecase cell
                           (string (write-string cell))
                           (t (write cell)))))))
                 (iter (for row in body)
                   (c:formatting-row ()
                     (iter (for cell in row)
                       (c:formatting-cell ()
                         (typecase cell
                           (string (write-string cell))
                           (t (write cell)))))))))
             (format-items (list item &optional user)
               (format t "Number of items listed: ~a~%~%" (iter (with j = 0)
                                                            (for i in list)
                                                            (when (typep i item)
                                                              (incf j))
                                                            (finally (return j))))
               (when user
                 (format t "~a:~%~%" (name-of user)))
               (apply #'format-table '("Index" "Name" "Class" "Wet" "Wetcap" "Mess" "Messcap")
                      (let ((j 0)) (iter (for i in list)
                                     (when (typep i item)
                                       (collect (list j
                                                      (name-of i)
                                                      (type-of i)
                                                      (if (typep i 'closed-bottoms) (coerce (sogginess-of i) 'long-float) nil)
                                                      (if (typep i 'closed-bottoms) (coerce (sogginess-capacity-of i) 'long-float) nil)
                                                      (if (typep i 'closed-bottoms) (coerce (messiness-of i) 'long-float) nil)
                                                      (if (typep i 'closed-bottoms) (coerce (messiness-capacity-of i) 'long-float) nil))))
                                     (incf j)))))
             (format-moves (user)
               (format t "~a:~%~%" (name-of user))
               (apply #'format-table '("Symbol" "Name" "Description")
                      (iter (for i in (moves-of user))
                        (when i (collect (list (class-name (class-of i)) (name-of i) (description-of i)))))))
             (format-user (user)
               (format t "Name: ~a~%Species: ~a~%Description: ~a~%~%"
                       (name-of user)
                       (species-of user)
                       (description-of user)))
             (check-allies ()
               (when (and (typep user 'unsigned-byte) (< allies-length user))
                 (format t "You only have ~d allies~%" allies-length)
                 (return-from yadfa-bin:lst))))
      (check-allies)
      (when inventory
        (with-effective-frame
          (format-items (inventory-of (player-of *game*)) inventory)))
      (when describe-zone
        (format t "~a~%" (get-zone-text (description-of (typecase describe-zone
                                                          (zone describe-zone)
                                                          (list (get-zone describe-zone))
                                                          (t (get-zone (position-of (player-of *game*)))))))))
      (when inventory-group
        (with-effective-frame
          (let ((a ()))
            (iter (for i in (inventory-of (player-of *game*)))
              (when (typep i inventory-group)
                (if (getf a (class-name (class-of i)))
                    (incf (second (getf a (class-name (class-of i)))))
                    (setf (getf a (class-name (class-of i))) (list (name-of (make-instance (class-name (class-of i)))) 1)))))
            (apply #'format-table '("Class Name" "Name" "Quantity")
                   (iter (for (key value) on a by #'cddr)
                     (collect (apply 'list key value)))))))
      (when wear
        (with-effective-frame
          (cond ((not user)
                 (format-items (wear-of (player-of *game*)) wear (player-of *game*))
                 (iter (for k in (allies-of *game*))
                   (format-items (wear-of k) wear k)))
                ((typep user 'integer)
                 (let ((selected-ally (nth user (allies-of *game*))))
                   (check-allies)
                   (format-items (wear-of selected-ally) wear selected-ally)))
                (t
                 (format-items (wear-of (player-of *game*)) wear (player-of *game*))))))
      (when moves
        (with-effective-frame
          (cond ((typep user 'real)
                 (let ((selected-ally (nth user (allies-of *game*))))
                   (format-moves selected-ally)))
                ((not user)
                 (format-moves (player-of *game*))
                 (iter (for k in (allies-of *game*))
                   (format-moves k)))
                (t (format-moves (player-of *game*))))))
      (when props
        (with-effective-frame
          (apply #'format-table '("Keyword" "Object")
                 (iter (for (a b) on (get-props-from-zone (position-of (player-of *game*))) by #'cddr)
                   (when b
                     (collect (list a (name-of b))))))))
      (let ((player-position (position-of (player-of *game*))))
        (declare (type list player-position))
        (destructuring-bind (x y z map) player-position
          (declare (type integer x y z)
                   (type symbol map))
          (let ((x-y-z (list x y z)))
            (declare (type list x-y-z))
            (flet ((z (delta direction x-y-z player-position map)
                     (declare (type keyword direction)
                              (type list delta x-y-z player-position)
                              (type symbol map))
                     (let ((position `(,@(mapcar #'+ x-y-z delta) ,map)))
                       (declare (type list position))
                       (when (and (get-zone position)
                                  (get-zone player-position)
                                  (not (getf-direction player-position direction :hidden))
                                  (not (hiddenp (get-zone position)))
                                  (or (and (s:memq direction '(:up :down)) (s:memq direction (stairs-of (get-zone player-position))))
                                      (not (s:memq direction '(:up :down)))))
                         (format t "~s ~a~%"
                                 direction
                                 (name-of (get-zone position)))))))
              (when directions
                (z '(1 0 0) :east x-y-z player-position map)
                (z '(-1 0 0) :west x-y-z player-position map)
                (z '(0 -1 0) :north x-y-z player-position map)
                (z '(0 1 0) :south x-y-z player-position map)
                (z '(0 0 1) :up x-y-z player-position map)
                (z '(0 0 -1) :down x-y-z player-position map)
                (when (warp-points-of (get-zone (position-of (player-of *game*))))
                  (iter (for (a b) on (warp-points-of (get-zone (position-of (player-of *game*)))) by #'cddr)
                    (when (and (get-zone b) (not (hiddenp (get-zone b))))
                      (format t "~s ~a~%" a (name-of (get-zone b)))))))))))
      (when position
        (format t "Your current position is ~s~%" (position-of (player-of *game*))))
      (when map
        (cond ((eq map t)
               (print-map t))
              (t (print-map
                  (destructuring-bind (x y z m) (position-of (player-of *game*))
                    (declare (type integer x y z)
                             (type symbol m)
                             (ignore z))
                    (list x y map m))))))
      (when descriptions
        (cond ((eq user t)
               (format-user (player-of *game*)))
              ((typep user 'unsigned-byte)
               (format-user (nth user (allies-of *game*))))
              (t
               (format-user (player-of *game*))
               (iter (for i in (allies-of *game*))
                 (format t "Name: ~a~%Species: ~a~%Description: ~a~%~%" (name-of i) (species-of i) (description-of i)))))))))
(defunassert yadfa-bin:get-stats (&key inventory wear prop item attack ally wield enemy)
    (ally (or null unsigned-byte type-specifier)
          wear (or null unsigned-byte type-specifier)
          inventory (or null unsigned-byte type-specifier)
          enemy (or null unsigned-byte type-specifier))
  "lists stats about various items in various places. @var{INVENTORY} is the index of an item in your inventory. @var{WEAR} is the index of what you or your ally is wearing. @var{PROP} is a keyword that refers to the prop you're selecting. @var{ITEM} is the index of an item that a prop has and is used to print information about that prop. @var{ATTACK} is a keyword referring to the move you or your ally has when showing that move. @var{ALLY} is the index of an ally on your team when selecting @var{INVENTORY} or @var{MOVE}, don't set @var{ALLY} if you want to select yourself."
  (when (and ally (list-length-> ally (allies-of *game*)))
    (write-line "That ally doesn't exist")
    (return-from yadfa-bin:get-stats))
  (let* ((selected-user (cond (ally (if (typep ally 'type-specifier)
                                        (find ally (allies-of *game*)
                                              :test (lambda (o e)
                                                      (typep e o)))
                                        (nth ally (allies-of *game*))))
                              ((and enemy *battle*)
                               (if (typep enemy 'type-specifier)
                                   (find enemy (enemies-of *battle*)
                                         :test (lambda (o e)
                                                 (typep e o)))
                                   (nth enemy (enemies-of *battle*))))
                              (t (player-of *game*))))
         (wear (typecase wear
                 (type-specifier (find wear (wear-of selected-user)
                                       :test (lambda (o e)
                                               (typep e o))))
                 (unsigned-byte (nth wear (wear-of selected-user)))))
         (inventory (typecase inventory
                      (type-specifier
                       (find inventory (inventory-of (player-of *game*))
                             :test (lambda (o e)
                                     (typep e o))))
                      (unsigned-byte
                       (nth inventory (inventory-of (player-of *game*)))))))
    (when wield
      (describe-item (wield-of selected-user)))
    (when inventory
      (describe-item inventory))
    (when wear
      (describe-item (find wear (wear-of selected-user)) t))
    (when attack
      (format t "Name:~a~%Description~a~%Energy Cost: ~f~%~%"
              (name-of (get-move attack selected-user))
              (description-of (get-move attack selected-user))
              (energy-cost-of (get-move attack selected-user))))
    (when prop
      (handle-user-input ()
          (*query-io* ((or (check-type prop (and (not null) symbol)) (null (getf (get-props-from-zone (position-of (player-of *game*))) prop)))
                       (prop)
                       :prompt-text "Enter a different prop, or exit and use (lst :props t) to get the list of props and try again"
                       :error-text "That prop doesn't exist")
                      ((null (nth item (items-of (getf (get-props-from-zone (position-of (player-of *game*)))
                                                       (the (and (not null) symbol) prop)))))
                       (item)
                       :prompt-text "Enter a different item"
                       :error-text "That item doesn't exist"))
        (describe-item (nth (the unsigned-byte item)
                            (items-of (getf (get-props-from-zone (position-of (player-of *game*)))
                                            (the (and (not null) symbol) prop)))))))))
(defunassert yadfa-world:interact (prop &rest keys &key list take action describe-action describe &allow-other-keys)
    (action (or keyword null)
            describe-action (or keyword null)
            prop symbol
            describe boolean
            take (or null keyword list))
  #.(format nil "interacts with @var{PROP}. @var{PROP} is a keyword, you can get these with @code{LST} with the @var{PROPS} parameter. setting @var{LIST} to non-NIL will list all the items and actions in the prop. you can take the items with the @var{TAKE} parameter. Setting this to an integer will take the item at that index, while setting it to @code{:ALL} will take all the items, setting it to @code{:BITCOINS} will take just the bitcoins. You can get this index with the @var{LIST} parameter. @var{ACTION} is a keyword referring to an action to perform, can also be found with the @var{LIST} parameter. You can also specify other keys when using @var{ACTION} and this function will pass those keys to that function. set @var{DESCRIBE-ACTION} to the keyword of the action to find out how to use it. Set @var{DESCRIBE} to @code{T} to print the prop's description.

~a."
            (xref yadfa-bin:lst :function))
  (when (typep take 'list) (loop for i in take do (check-type i unsigned-byte)))
  (flet ((format-table (header &rest body)
           (c:formatting-table (t :x-spacing 20)
             (c:with-text-style (*query-io* (c:make-text-style nil :bold nil))
               (c:formatting-row ()
                 (iter (for cell in header)
                   (c:formatting-cell ()
                     (typecase cell
                       (string (write-string cell))
                       (t (write cell)))))))
             (iter (for row in body)
               (c:formatting-row ()
                 (iter (for cell in row)
                   (c:formatting-cell ()
                     (typecase cell
                       (string (write-string cell))
                       (t (write cell))))))))))
    (when list
      (with-effective-frame
        (format t "Bitcoins: ~a~%~%" (get-bitcoins-from-prop prop (position-of (player-of *game*))))
        (apply #'format-table '("Index" "Name" "Class")
               (iter (for i in (get-items-from-prop prop (position-of (player-of *game*))))
                 (declaring fixnum for j upfrom 0)
                 (collect (list j (name-of i) (type-of i)))))
        (format t "~%~%Actions: ")
        (iter (for (key value) on (actions-of (getf (get-props-from-zone (position-of (player-of *game*))) prop)) by #'cddr)
          (when value
            (format t "~s " key)
            (finally (write-char #\Newline))))))
    (when take
      (cond ((eq take :all)
             (setf (inventory-of (player-of *game*)) (append* (get-items-from-prop prop (position-of (player-of *game*))) (inventory-of (player-of *game*))))
             (setf (get-items-from-prop prop (position-of (player-of *game*))) '())
             (incf (bitcoins-of (player-of *game*)) (get-bitcoins-from-prop prop (position-of (player-of *game*))))
             (setf (get-bitcoins-from-prop prop (position-of (player-of *game*))) 0))
            ((eq take :bitcoins)
             (incf (bitcoins-of (player-of *game*)) (get-bitcoins-from-prop prop (position-of (player-of *game*))))
             (setf (get-bitcoins-from-prop prop (position-of (player-of *game*))) 0))
            (t
             (iter (for i in take)
               (push (nth i (get-items-from-prop prop (position-of (player-of *game*)))) (inventory-of (player-of *game*))))
             (iter (for i in (sort (copy-tree take) #'>))
               (setf (get-items-from-prop prop (position-of (player-of *game*))) (remove-nth i (get-items-from-prop prop (position-of (player-of *game*)))))))))
    (when action
      (apply (coerce (action-lambda (getf-action-from-prop (position-of (player-of *game*)) prop action))
                     'function)
             (getf (get-props-from-zone (position-of (player-of *game*))) prop)
             :allow-other-keys t keys))
    (when describe-action
      (format t "Keyword: ~a~%~%Other Parameters: ~w~%~%Documentation: ~a~%~%Describe: ~a~%~%"
              describe-action
              (rest (lambda-list (action-lambda (getf-action-from-prop (position-of (player-of *game*)) prop describe-action))))
              (documentation (getf (actions-of (getf (get-props-from-zone (position-of (player-of *game*))) prop)) describe-action) t)
              (with-output-to-string (s)
                (let ((*standard-output* s))
                  (describe (action-lambda (getf-action-from-prop (position-of (player-of *game*)) prop describe-action)))))))
    (when describe
      (format t "~a~%" (description-of (getf (get-props-from-zone (position-of (player-of *game*))) prop))))))
(defunassert yadfa-bin:wear (&key (inventory 0) (wear 0) user)
    (user (or null unsigned-byte)
          wear unsigned-byte
          inventory (or type-specifier unsigned-byte))
  #.(format nil "Wear an item in your inventory. @var{WEAR} is the index you want to place this item. Smaller index refers to outer clothing. @var{INVENTORY} is an index in your inventory of the item you want to wear. You can also give it a type specifier which will pick the first item in your inventory of that type. @var{USER} is an index of an ally. Leave this at @code{NIL} to refer to yourself.

~a, ~a, and ~a."
            (xref yadfa-bin:unwear :function) (xref yadfa-bin:change :function) (xref yadfa-bin:lst :function))
  (handle-user-input ((selected-user (if user
                                         (nth user (allies-of *game*))
                                         (player-of *game*)))
                      (item (typecase inventory
                              (unsigned-byte
                               (nth inventory (inventory-of (player-of *game*))))
                              (type-specifier
                               (find inventory (inventory-of (player-of *game*))
                                     :test #'(lambda (type-specifier obj)
                                               (typep obj type-specifier))))))
                      i a
                      (wear-length (list-length (wear-of selected-user))))
      (*query-io* ((when (list-length-> 1 (inventory-of (player-of *game*)))
                     (format t "~a doesn't have any clothes to put on~%" (name-of selected-user))
                     (return-from yadfa-bin:wear))
                   ())
                  ((not item)
                   (inventory)
                   :prompt-text "Enter a different item"
                   :error-text  "INVENTORY isn't a valid item")
                  ((not (typep item 'clothing))
                   (inventory)
                   :prompt-text "Enter a different item"
                   :error-text (format nil "That ~a isn't something you can wear~%" (name-of item)))
                  ((< wear-length wear)
                   (wear)
                   :prompt-text "Enter a different index"
                   :error-text (format nil "“:WEAR ~d” doesn't refer to a valid position as it can't go past the items you're current wearing which is currently ~d"
                                       wear
                                       wear-length)))
    (cond ((let ((not-wear (typecase (must-not-wear*-of (get-zone (position-of (player-of *game*))))
                             (cons (must-not-wear*-of (get-zone (position-of (player-of *game*)))))
                             (symbol (gethash (must-not-wear*-of *game*) (must-not-wear*-of (get-zone (position-of (player-of *game*)))))))))
             (and (typep item (car not-wear)) (not (funcall (coerce (cdr not-wear) 'function) selected-user))))
           (return-from yadfa-bin:wear))
          ((and (> wear 0) (iter (for i in (butlast (wear-of selected-user) (- wear-length wear)))
                             (when (and (typep i 'closed-bottoms) (lockedp i))
                               (format t "~a can't remove ~a ~a to put on ~a ~a as it's locked~%"
                                       (name-of selected-user)
                                       (if (malep selected-user) "his" "her")
                                       (name-of i)
                                       (if (malep selected-user) "his" "her")
                                       (name-of item))
                               (leave t))))
           (return-from yadfa-bin:wear)))
    (setf a (insert (wear-of selected-user) item wear)
          i (iter (for outer in (reverse (subseq a 0 (1+ wear))))
              (with b = (reverse a))
              (when (and (typep outer 'bottoms) (thickness-capacity-of outer) (> (fast-thickness b outer) (thickness-capacity-of outer)))
                (leave (thickest (cdr (s:memq outer a)))))))
    (if i
        (format t "~a struggles to fit ~a ~a over ~a ~a in a hilarious fashion but fail to do so.~%"
                (name-of selected-user)
                (if (malep selected-user) "his" "her")
                (name-of item)
                (if (malep selected-user) "his" "her")
                (name-of i))
        (progn (when *battle*
                 (format t "The ~a you're battling stops and waits for you to put on your ~a because Pouar never prevented this function from being called in battle~%"
                         (if (list-length-< 1 (enemies-of *battle*)) "enemies" "enemy")
                         (name-of item)))
               (format t "~a puts on ~a ~a~%" (name-of selected-user) (if (malep selected-user) "his" "her") (name-of item))
               (a:deletef (inventory-of (player-of *game*)) item :count 1)
               (setf (wear-of selected-user) a)))))
(defunassert yadfa-bin:unwear (&key (inventory 0) (wear 0) user)
    (user (or unsigned-byte null)
          inventory unsigned-byte
          wear (or type-specifier unsigned-byte))
  #.(format nil "Unwear an item you're wearing. @var{INVENTORY} is the index you want to place this item. @var{WEAR} is the index of the item you're wearing that you want to remove. You can also set @var{WEAR} to a type specifier for the outer most clothing of that type. @var{USER} is a integer referring to the index of an ally. Leave at @code{NIL} to refer to yourself

~a, ~a, and ~a."
            (xref yadfa-bin:wear :function) (xref yadfa-bin:change :function) (xref yadfa-bin:lst :function))
  (handle-user-input ((selected-user (if user
                                         (nth user (allies-of *game*))
                                         (player-of *game*)))
                      (item (typecase wear
                              (unsigned-byte
                               (nth wear (wear-of (player-of *game*))))
                              (type-specifier
                               (find wear (wear-of (player-of *game*))
                                     :test #'(lambda (type-specifier obj)
                                               (typep obj type-specifier))))))
                      (inventory-length (list-length (inventory-of (player-of *game*)))))
      (*query-io* ((when (list-length-> 1 (wear-of selected-user))
                     (format t "~a isn't wearing any clothes to remove~%" (name-of selected-user))
                     (return-from yadfa-bin:unwear))
                   ())
                  ((not item)
                   (wear)
                   :prompt-text "Enter a different item"
                   :error-text "WEAR isn't a valid item")
                  ((< inventory-length inventory)
                   (inventory)
                   :prompt-text "Enter a different index"
                   :error-text (format nil "“:INVENTORY ~d” doesn't refer to a valid position as it can't go past the items you currently have in your inventory which is currently ~d~%"
                                       inventory inventory-length)))
    (cond ((and
            (not (eq (player-of *game*) selected-user))
            (typep item 'diaper)
            (typep user '(not potty-trained-team-member))
            (list-length-> 2 (filter-items (wear-of selected-user) 'diaper)))
           (format t "Letting ~a go without padding is a really bad idea. Don't do it.~%"
                   (name-of selected-user))
           (return-from yadfa-bin:unwear))
          ((let ((wear (typecase (must-wear*-of (get-zone (position-of (player-of *game*))))
                         (cons (must-wear*-of (get-zone (position-of (player-of *game*)))))
                         (symbol (gethash (must-wear*-of *game*)
                                          (must-wear*-of (get-zone (position-of (player-of *game*)))))))))
             (and (typep item (car wear))
                  (list-length->= 1 (filter-items (wear-of selected-user) (car wear)))
                  (not (funcall (coerce (cdr wear) 'function) selected-user))))
           (return-from yadfa-bin:unwear))
          ((iter (for i in (butlast (wear-of selected-user) (- (list-length (wear-of selected-user)) (position item (wear-of selected-user)) 1)))
             (when (and (typep i 'closed-bottoms) (lockedp i))
               (format t "~a can't remove ~a ~a to take off ~a ~a as it's locked~%"
                       (name-of selected-user)
                       (if (malep selected-user) "his" "her")
                       (name-of i)
                       (if (malep selected-user) "his" "her")
                       (name-of item))
               (leave t)))
           (return-from yadfa-bin:unwear)))
    (when *battle*
      (format t "The ~a you're battling stops and waits for you to take off your ~a because Pouar never prevented this function from being called in battle~%"
              (if (list-length-< 1 (enemies-of *battle*))
                  "enemies"
                  "enemy")
              (name-of item)))
    (format t "~a takes off ~a ~a~%" (name-of selected-user) (if (malep selected-user) "his" "her") (name-of item))
    (a:deletef (wear-of (player-of *game*)) item :count 1)
    (insertf (inventory-of (player-of *game*)) item inventory)))
(defunassert yadfa-bin:change (&key (inventory 0) (wear 0) user)
    (user (or null unsigned-byte)
          inventory (or type-specifier unsigned-byte)
          wear (or type-specifier unsigned-byte))
  #.(format nil "Change one of the clothes you're wearing with one in your inventory. @var{WEAR} is the index of the clothing you want to replace. Smaller index refers to outer clothing. @var{INVENTORY} is an index in your inventory of the item you want to replace it with. You can also give @var{INVENTORY} and @var{WEAR} a quoted symbol which can act as a type specifier which will pick the first item in your inventory of that type. @var{USER} is an index of an ally. Leave this at @code{NIL} to refer to yourself.

~a, ~a, and ~a."
            (xref yadfa-bin:unwear :function) (xref yadfa-bin:wear :function) (xref yadfa-bin:lst :function))
  (handle-user-input ((selected-user (if user
                                         (nth user (allies-of *game*))
                                         (player-of *game*)))
                      (inventory (typecase inventory
                                   (unsigned-byte
                                    (nth inventory (inventory-of (player-of *game*))))
                                   (type-specifier
                                    (find inventory (inventory-of (player-of *game*))
                                          :test #'(lambda (type-specifier obj)
                                                    (typep obj type-specifier))))))
                      (wear (typecase wear
                              (unsigned-byte
                               (nth wear (wear-of (player-of *game*))))
                              (type-specifier
                               (find wear (wear-of (player-of *game*))
                                     :test #'(lambda (type-specifier obj)
                                               (typep obj type-specifier))))))
                      i a)
      (*query-io* ((when (list-length-> 1 (wear-of selected-user))
                     (format t "~a isn't wearing any clothes to change~%" (name-of selected-user))
                     (return-from yadfa-bin:change))
                   ())
                  ((not inventory)
                   (inventory)
                   :prompt-text "Enter a different item"
                   :error-text "INVENTORY isn't valid")
                  ((not wear)
                   (inventory)
                   :prompt-text "Enter a different item"
                   :error-text  "WEAR isn't valid")
                  ((not (typep inventory 'clothing))
                   (inventory)
                   :prompt-text "Enter a different item"
                   :error-text (format nil "That ~a isn't something you can wear" (name-of inventory))))
    (cond ((and
            (typep selected-user '(not potty-trained-team-member))
            (typep inventory 'pullup)
            (typep wear 'diaper)
            (list-length-> 2 (filter-items (wear-of selected-user) 'diaper)))
           (format t "Does ~a look ready for pullups to you?~%" (name-of selected-user))
           (return-from yadfa-bin:change))
          ((and
            (typep selected-user '(not potty-trained-team-member))
            (not (typep inventory 'diaper))
            (typep wear 'diaper)
            (list-length-> 2 (filter-items (wear-of selected-user) 'diaper)))
           (format t "letting ~a go without padding is a really bad idea. Don't do it.~%" (name-of selected-user))
           (return-from yadfa-bin:change))
          ((let ((wear (typecase (must-wear*-of (get-zone (position-of (player-of *game*))))
                         (cons (must-wear*-of (get-zone (position-of (player-of *game*)))))
                         (symbol (gethash (must-wear*-of *game*) (must-wear*-of (get-zone (position-of (player-of *game*))))))))
                 (not-wear (typecase (must-not-wear*-of (get-zone (position-of (player-of *game*))))
                             (cons (must-not-wear*-of (get-zone (position-of (player-of *game*)))))
                             (symbol (gethash (must-not-wear*-of *game*) (must-not-wear*-of (get-zone (position-of (player-of *game*)))))))))
             (or (and (not (typep inventory (car wear)))
                      (typep wear (car wear))
                      (list-length->= 1 (filter-items (wear-of selected-user) (car wear)))
                      (not (funcall (coerce (cdr not-wear) 'function) selected-user)))
                 (and (typep inventory (car not-wear)) (not (funcall (coerce (cdr not-wear) 'function) selected-user)))))
           (return-from yadfa-bin:change))
          ((and
            (iter (for i in (butlast (wear-of selected-user) (- (list-length (wear-of selected-user)) (position wear (wear-of selected-user)) 1)))
              (when (and (typep i 'closed-bottoms) (lockedp i))
                (format t "~a can't remove ~a ~a to put on ~a ~a as it's locked~%"
                        (name-of selected-user)
                        (if (malep selected-user) "his" "her")
                        (name-of i)
                        (if (malep selected-user) "his" "her")
                        (name-of inventory))
                (leave t))))
           (return-from yadfa-bin:change)))
    (setf a (substitute inventory wear (wear-of selected-user) :count 1)
          i (iter (for outer in (reverse (subseq a 0 (1+ (position inventory a)))))
              (with b = (reverse a))
              (when (and (typep outer 'bottoms) (thickness-capacity-of outer) (> (fast-thickness b outer) (thickness-capacity-of outer)))
                (leave outer))))
    (if i
        (format t
                "~a struggles to fit ~a ~a over ~a ~a in a hilarious fashion but fail to do so.~%"
                (name-of selected-user)
                (if (malep selected-user) "his" "her")
                (name-of i)
                (if (malep selected-user) "his" "her")
                (name-of inventory))
        (progn (when *battle*
                 (format t "The ~a you're battling stops and waits for you to put on your ~a because Pouar never prevented this function from being called in battle~%"
                         (if (list-length-< 1 (enemies-of *battle*)) "enemies" "enemy")
                         (name-of inventory)))
               (format t "~a changes out of ~a ~a and into ~a ~a~%"
                       (name-of selected-user)
                       (if (malep selected-user) "his" "her")
                       (name-of wear)
                       (if (malep selected-user) "his" "her")
                       (name-of inventory))
               (substitutef (inventory-of selected-user) wear inventory :count 1)
               (setf (wear-of selected-user) a)))))
(defunassert yadfa-battle:fight (attack &key target friendly-target)
    (target (or null unsigned-byte type-specifier)
            friendly-target (or null unsigned-byte type-specifier)
            attack (or symbol boolean))
  "Use a move on an enemy. @var{ATTACK} is either a keyword which is the indicator to select an attack that you know, or @code{T} for default. @var{TARGET} is the index or type specifier of the enemy you're attacking. @var{FRIENDLY-TARGET} is a member on your team you're using the move on instead. Only specify either a @var{FRIENDLY-TARGET} or @var{TARGET}. Setting both might make the game's code unhappy"
  (let ((selected-target (cond (target
                                (let ((a (typecase target
                                           (unsigned-byte (nth target (enemies-of *battle*)))
                                           (type-specifier (find target (enemies-of *battle*)
                                                                 :test (lambda (o e)
                                                                         (typep e o)))))))
                                  (or a
                                      (progn
                                        (write-line "That target doesn't exist")
                                        (return-from yadfa-battle:fight)))))
                               (friendly-target
                                (let ((a (typecase friendly-target
                                           (unsigned-byte (nth friendly-target (team-of *game*)))
                                           (type-specifier (find friendly-target (team-of *game*)
                                                                 :test (lambda (o e)
                                                                         (typep e o)))))))
                                  (or a
                                      (progn
                                        (write-line "That target doesn't exist")
                                        (return-from yadfa-battle:fight)))))
                               (t (iter (for i in (enemies-of *battle*))
                                    (when (>= (health-of i) 0)
                                      (leave i)))))))
    (process-battle :attack attack :selected-target selected-target)))
(defunassert yadfa-battle:stats (&key user enemy)
    (user (or unsigned-byte null)
          enemy (or unsigned-byte null))
  "Prints the current stats in battle, essentially this game's equivalent of a health and energy bar in battle. @var{USER} is the index of the member in your team, @var{ENEMY} is the index of the enemy in battle. Set both to @code{NIL} to show the stats for everyone."
  (cond (user
         (present-stats (nth user (team-of *game*))))
        (enemy
         (present-stats (nth enemy (enemies-of *battle*))))
        (t
         (format t "Your team:~%~%")
         (iter (for i in (team-of *game*))
           (present-stats i))
         (format t "Their team:~%~%")
         (iter (for i in (enemies-of *battle*))
           (present-stats i)))))
(defunassert yadfa-world:stats (&optional user)
    (user (or unsigned-byte boolean))
  "Prints the current stats, essentially this game's equivalent of a health and energy bar in battle. Set @var{USER} to the index of an ally to show that ally's stats or set it to @code{T} to show your stats, leave it at @code{NIL} to show everyone's stats"
  (cond ((eq user t)
         (present-stats (player-of *game*)))
        (user
         (present-stats (nth user (allies-of *game*))))
        (t
         (iter (for i in (cons (player-of *game*) (allies-of *game*)))
           (present-stats i)))))
(defunassert yadfa-world:go-potty (&key prop wet mess pull-pants-down user)
    (user (or null real)
          prop (or null keyword)
          wet (or boolean real)
          mess (or boolean real))
  "Go potty. @var{PROP} is a keyword identifying the prop you want to use. If it's a toilet, use the toilet like a big boy. if it's not. Go potty on it like an animal. If you want to wet yourself, leave @var{PROP} as @code{NIL}. @var{WET} is the amount you want to pee in ml. @var{MESS} is the amount in cg, set @var{WET} and/or @var{MESS} to @code{T} to empty yourself completely. set @var{PULL-PANTS-DOWN} to non-NIL to pull your pants down first. @var{USER} is the index value of an ALLY you have. Set this to @code{NIL} if you're referring to yourself"
  (let ((this-prop (getf (get-props-from-zone (position-of (player-of *game*))) prop))
        (selected-user (if user
                           (nth user (allies-of *game*))
                           (player-of *game*))))
    (when (and prop (not this-prop))
      (format t "that PROP doesn't exist in this zone~%")
      (return-from yadfa-world:go-potty))
    (typecase this-prop
      (yadfa-props:toilet
       (potty-on-toilet this-prop
                        :wet (if user t wet)
                        :mess (if user t mess)
                        :pants-down pull-pants-down
                        :user selected-user))
      (t
       (potty-on-self-or-prop this-prop
                              :wet (if user t wet)
                              :mess (if user t mess)
                              :pants-down pull-pants-down
                              :user selected-user)))))
(defunassert yadfa-world:tickle (ally)
    (ally unsigned-byte)
  "Tickle an ally. @var{ALLY} is an integer that is the index of you allies"
  (when (list-length-> ally (allies-of *game*))
    (write-line "That ally doesn't exist")
    (return-from yadfa-world:tickle))
  (let ((selected-ally (nth ally (allies-of *game*))))
    (cond ((getf (attributes-of selected-ally) :not-ticklish)
           (format t "~a isn't ticklish"
                   (name-of selected-ally)))
          ((>= (bladder/contents-of selected-ally) (bladder/potty-dance-limit-of selected-ally))
           (format t "~a: Gah! No! Stop! *falls over and laughs while thrashing about then uncontrollably floods ~aself like an infant*~%~%*~a stops tickling*~%~%~a: Looks like the baby wet ~aself~%~%*~a slowly stands up while still wetting ~aself and grumbles*~%~%"
                   (name-of selected-ally)
                   (if (malep selected-ally) "him" "her")
                   (name-of (player-of *game*))
                   (name-of (player-of *game*))
                   (if (malep selected-ally) "him" "her")
                   (name-of selected-ally)
                   (if (malep selected-ally) "him" "her"))
           (wet :wetter selected-ally))
          ((and (>= (bladder/contents-of selected-ally) (bladder/need-to-potty-limit-of selected-ally)) (= (random 5) 0))
           (format t "~a: Gah! No! Stop! *falls over and laughs while thrashing about for about 30 seconds then uncontrollably floods ~aself like an infant*~%~%*~a stops tickling*~%~%~a: Looks like the baby wet ~aself~%~%*~a slowly stands up while still wetting ~aself and grumbles*~%~%"
                   (name-of selected-ally)
                   (if (malep selected-ally) "him" "her")
                   (name-of (player-of *game*))
                   (name-of (player-of *game*))
                   (if (malep selected-ally) "him" "her")
                   (name-of selected-ally)
                   (if (malep selected-ally) "him" "her"))
           (wet :wetter selected-ally))
          (t
           (format t "~a: Gah! No! Stop! *falls over and laughs while thrashing about for a few minutes until you get bored and stop*~%~%*~a slowly stands up exhausted from the tickling and grumbles*~%~%"
                   (name-of selected-ally)
                   (name-of selected-ally))))))
(defunassert yadfa-world:wash-all-in (&optional prop)
    (prop (or keyword null))
  "washes your dirty diapers and all the clothes you've ruined. @var{PROP} is a keyword identifying the washer you want to put it in. If you're washing it in a body of water, leave @var{PROP} out."
  (cond
    ((and prop (not (typep (getf (get-props-from-zone (position-of (player-of *game*))) prop) 'yadfa-props:washer)))
     (write-line "That's not a washer"))
    ((and (not prop) (not (underwaterp (get-zone (position-of (player-of *game*)))))) (format t "There's no where to wash that~%"))
    ((underwaterp (get-zone (position-of (player-of *game*))))
     (wash (inventory-of (player-of *game*)))
     (write-line "You washed all your soggy and messy clothing. Try not to wet and mess them next time"))
    (t (wash-in-washer (getf (get-props-from-zone (position-of (player-of *game*))) prop)))))
(defunassert yadfa-bin:toss (&rest items)
    (items list)
  "Throw an item in your inventory away. @var{ITEM} is the index of the item in your inventory"
  (let ((value (iter (for i in items)
                 (unless (typep i 'unsigned-byte)
                   (leave i)))))
    (when value
      (error 'type-error :datum value :expected-type 'unsigned-byte)))
  (let ((items (sort (remove-duplicates items) #'<)))
    (setf items (iter (generate i in items)
                  (for j in (inventory-of (player-of *game*)))
                  (declaring fixnum for k upfrom 0)
                  (when (first-iteration-p)
                    (next i))
                  (when (= k i)
                    (collect j)
                    (next i))))
    (unless items
      (format t "Those items aren't valid")
      (return-from yadfa-bin:toss))
    (iter (for i in items)
      (unless (tossablep i)
        (format t "To avoid breaking the game, you can't toss your ~a." (name-of i))
        (return-from yadfa-bin:toss)))
    (iter (for i in items)
      (format t "You send ~a straight to /dev/null~%" (name-of i)))
    (a:deletef (inventory-of (player-of *game*)) items
               :test (lambda (o e)
                       (s:memq e o)))))
(defunassert yadfa-world:place (prop &rest items)
    (items list
           prop symbol)
  "Store items in a prop. @var{ITEMS} is a list of indexes of the items in your inventory. @var{PROP} is a keyword"
  (let ((value (iter (for i in items)
                 (unless (typep i 'integer)
                   (leave i)))))
    (when value
      (error 'type-error :datum value :expected-type 'integer)))
  (iter (for i in items) (check-type i integer))
  (unless (getf (get-props-from-zone (position-of (player-of *game*))) prop)
    (write-line "That prop doesn't exist")
    (return-from yadfa-world:place))
  (unless (placeablep (getf (get-props-from-zone (position-of (player-of *game*))) prop))
    (write-line "To avoid breaking the game, you can't place that item here.")
    (return-from yadfa-world:place))
  (let ((items (sort (remove-duplicates items) #'<)))
    (setf items (iter (generate i in items)
                  (for j in (player-of *game*))
                  (declaring fixnum for k upfrom 0)
                  (when (first-iteration-p)
                    (next i))
                  (when (= k i)
                    (collect j)
                    (next i))))
    (unless items
      (format t "Those items aren't valid")
      (return-from yadfa-world:place))
    (iter (for i in items)
      (format t "You place your ~a on the ~a~%" (name-of i) (name-of (getf (get-props-from-zone (position-of (player-of *game*))) prop)))
      (push i (get-items-from-prop prop (position-of (player-of *game*)))))
    (a:deletef (inventory-of (player-of *game*)) items
               :test (lambda (o e)
                       (s:memq e o)))))
(defun yadfa-battle:run ()
  "Run away from a battle like a coward"
  (cond ((continue-battle-of (get-zone (position-of (player-of *game*))))
         (write-line "Can't run from this battle")
         (return-from yadfa-battle:run))
        ((and (>=
               (bladder/contents-of (player-of *game*))
               (bladder/need-to-potty-limit-of (player-of *game*)))
              (>=
               (bowels/contents-of (player-of *game*))
               (bowels/need-to-potty-limit-of (player-of *game*))))
         (format t
                 "~a wet and messed ~aself in fear and ran away like a coward~%"
                 (name-of (player-of *game*))
                 (if (malep (player-of *game*))
                     "him"
                     "her"))
         (wet)
         (mess))
        ((>= (bladder/contents-of (player-of *game*)) (bladder/need-to-potty-limit-of (player-of *game*)))
         (format t "~a wet ~aself in fear and ran away like a coward~%" (name-of (player-of *game*))
                 (if (malep (player-of *game*))
                     "him"
                     "her"))
         (wet))
        ((>= (bowels/contents-of (player-of *game*)) (bowels/need-to-potty-limit-of (player-of *game*)))
         (format t "~a messed ~aself in fear and ran away like a coward~%" (name-of (player-of *game*))
                 (if (malep (player-of *game*))
                     "him"
                     "her"))
         (mess))
        (t
         (format t "~a ran away like a coward~%" (name-of (player-of *game*)))))
  (s:nix *battle*)
  (switch-user-packages))
(defunassert yadfa-world:use-item (item &rest keys &key user action &allow-other-keys)
    (item (or unsigned-byte type-specifier)
          action (or null keyword)
          user (or null unsigned-byte))
  "Uses an item. @var{ITEM} is an index of an item in your inventory. @var{USER} is an index of an ally. Setting this to @code{NIL} will use it on yourself. @var{ACTION} is a keyword when specified will perform a special action with the item, all the other keys specified in this function will be passed to that action. @var{ACTION} doesn't work in battle."
  (declare (ignorable action))
  (handle-user-input ((selected-item (typecase item
                                       (unsigned-byte
                                        (nth item (inventory-of (player-of *game*))))
                                       (type-specifier
                                        (find item (inventory-of (player-of *game*))
                                              :test #'(lambda (type-specifier obj)
                                                        (typep obj type-specifier))))))
                      ret
                      (allies-length (list-length (allies-of *game*))))
      (*query-io* ((null selected-item)
                   (item)
                   :prompt-text "Enter a different item"
                   :error-text (format nil "You only have ~a items" (length (inventory-of (player-of *game*)))))
                  ((and user (< allies-length user))
                   (user)
                   :prompt-text "Enter a different user"
                   :error-text (format nil "You only have ~d allies" allies-length)))
    (incf (time-of *game*))
    (let ((this-user (if user (nth user (allies-of *game*)) (player-of *game*))))
      (setf ret (apply #'use-item% selected-item (player-of *game*)
                       :target this-user
                       keys))
      (process-potty)
      (iter (for i in (allies-of *game*))
        (process-potty i))
      ret)))
(defunassert yadfa-battle:use-item (item &key target enemy-target)
    (item (or unsigned-byte type-specifier)
          target (or null unsigned-byte type-specifier)
          enemy-target (or null unsigned-byte type-specifier))
  "Uses an item. @var{ITEM} is an index of an item in your inventory. @var{TARGET} is an index or type specifier of a character in your team. Setting this to 0 will use it on yourself. @var{ENEMY-TARGET} is an index or type specifier of an enemy in battle if you're using it on an enemy in battle. Only specify either a @var{TARGET} or @var{ENEMY-TARGET}. Setting both might make the game's code unhappy"
  (handle-user-input ((selected-item (typecase item
                                       (unsigned-byte
                                        (nth item (inventory-of (player-of *game*))))
                                       (type-specifier
                                        (find item (inventory-of (player-of *game*))
                                              :test #'(lambda (type-specifier obj)
                                                        (typep obj type-specifier))))))
                      (selected-target (cond ((and target enemy-target)
                                              (format t "Only specify TARGET or ENEMY-TARGET. Not both.")
                                              (return-from yadfa-battle:use-item))
                                             (enemy-target
                                              (or (typecase enemy-target
                                                    (unsigned-byte (nth enemy-target (enemies-of *battle*)))
                                                    (type-specifier (find enemy-target (enemies-of *battle*)
                                                                          :test (lambda (o e)
                                                                                  (typep e o)))))))
                                             (target
                                              (or (typecase target
                                                    (unsigned-byte (nth target (team-of *game*)))
                                                    (type-specifier (find target (team-of *game*)
                                                                          :test (lambda (o e)
                                                                                  (typep e o)))))))
                                             (t (iter (for i in (enemies-of *battle*))
                                                  (when (>= (health-of i) 0)
                                                    (leave i)))))))
      (*query-io* ((not selected-item)
                   (item)
                   :error-text (format nil "You don't have that item~%")
                   :prompt-text "Enter a different item")
                  ((and target (not selected-target))
                   (target)
                   :error-text "That target doesn't exist"
                   :prompt-text "Enter a different TARGET")
                  ((and enemy-target (not selected-target))
                   (enemy-target)
                   :error-text "That target doesn't exist"
                   :prompt-text "Enter a different ENEMY-TARGET"))
    (process-battle
     :item selected-item
     :selected-target selected-target)))
(defunassert yadfa-battle:reload (&optional ammo-type)
    (ammo-type (or null type-specifier))
  (let* ((inventory (inventory-of (player-of *game*)))
         (user (first (turn-queue-of *battle*)))
         (user-name (name-of user))
         (weapon (wield-of user))
         (weapon-name (name-of weapon))
         (ammo-capacity (ammo-capacity-of (wield-of user)))
         (weapon-ammo-type (ammo-type-of weapon)))
    (unless weapon
      (format t "~a isn't carrying a weapon~%" user-name)
      (return-from yadfa-battle:reload))
    (unless (and weapon-ammo-type (> ammo-capacity 0))
      (format t "~a's ~a doesn't take ammo~%" user-name weapon-name)
      (return-from yadfa-battle:reload))
    (when
        (list-length-<= ammo-capacity (ammo-of weapon))
      (format t "~a's ~a is already full~%" user-name weapon-name)
      (return-from yadfa-battle:reload))
    (handle-user-input ((selected-ammo-type (or ammo-type
                                                (iter (for i in inventory)
                                                  (when (typep i weapon-ammo-type)
                                                    (leave i)))
                                                (progn (format t "~a doesn't have any ammo~%" (name-of user))
                                                       (return-from yadfa-battle:reload)))))
        (*query-io*
         ((and ammo-type (not (subtypep ammo-type weapon-ammo-type)))
          (ammo-type)
          :error-text (format nil "~a ~a doesn't take that ammo"
                              user-name
                              weapon-name)
          :prompt-text "Select different ammo")
         ((and ammo-type (iter (for i in inventory)
                           (when (typep i ammo-type)
                             (leave t))))
          (ammo-type)
          :error-text (format nil "~a doesn't have that ammo" user-name)
          :prompt-text "Select different ammo"))
      (process-battle :reload selected-ammo-type))))
(defunassert yadfa-world:reload (ammo-type &optional user)
    (ammo-type (and type-specifier (not null))
               user (or unsigned-byte null))
  (let* ((user (if user
                   (nth user (allies-of *game*))
                   (player-of *game*)))
         (user-name (name-of user))
         (weapon (wield-of user))
         (weapon-ammo-type (ammo-type-of weapon))
         (weapon-capacity (ammo-capacity-of weapon))
         (weapon-name (name-of weapon))
         (reload-count (reload-count-of weapon))
         (player (player-of *game*)))
    (unless (wield-of user)
      (format t "~a isn't carrying a weapon~%" user-name)
      (return-from yadfa-world:reload))
    (unless (and weapon-ammo-type (> weapon-capacity 0))
      (format t "~a's ~a doesn't take ammo~%" user-name weapon-name)
      (return-from yadfa-world:reload))
    (when (list-length-<= weapon-capacity (ammo-of (wield-of user)))
      (format t "~a's ~a is already full~%" user-name weapon-name)
      (return-from yadfa-world:reload))
    (unless (subtypep ammo-type weapon-ammo-type)
      (format t "~a ~a doesn't take that ammo~%" user-name weapon-name)
      (return-from yadfa-world:reload))
    (unless (iter (for i in (inventory-of player))
              (when (typep i ammo-type)
                (leave t)))
      (format t "~a doesn't have that ammo~%" user-name)
      (return-from yadfa-world:reload))
    (format t "~a reloaded ~a ~a" user-name (if (malep user) "his" "her") weapon-name)
    (iter (with count = 0)
      (for item in (inventory-of player))
      (when (or (list-length-<= weapon-capacity (ammo-of weapon))
                (and reload-count (>= count reload-count)))
        (leave t))
      (when (and (typep item ammo-type) (typep item weapon-ammo-type))
        (push item (ammo-of weapon))
        (a:deletef item (inventory-of player) :count 1)))))
(defunassert yadfa-bin:wield (&key user inventory)
    (user (or unsigned-byte null)
          inventory (or unsigned-byte type-specifier))
  "Wield an item. Set @var{INVENTORY} to the index or a type specifier of an item in your inventory to wield that item. Set @var{USER} to the index of an ally to have them to equip it or leave it @code{NIL} for the player."
  (let* ((selected-user (if user
                            (nth user (allies-of *game*))
                            (player-of *game*)))
         (item (typecase inventory
                 (unsigned-byte
                  (nth inventory (inventory-of (player-of *game*))))
                 ((or list (and symbol (not keyword)))
                  (find inventory (inventory-of (player-of *game*))
                        :test #'(lambda (type-specifier obj)
                                  (typep obj type-specifier)))))))
    (cond ((not item)
           (format t "INVENTORY isn't valid~%")
           (return-from yadfa-bin:wield)))
    (when *battle*
      (format t "The ~a you're battling stops and waits for you to equip your ~a because Pouar never prevented this function from being called in battle~%"
              (if (list-length-< 1 (enemies-of *battle*)) "enemies" "enemy")
              (name-of item)))
    (format t "~a equips his ~a ~a~%"
            (name-of selected-user)
            (if (malep selected-user) "his" "her")
            (name-of item))
    (a:deletef (inventory-of (player-of *game*)) item :count 1)
    (when (wield-of selected-user)
      (push (wield-of selected-user) (inventory-of (player-of *game*))))
    (setf (wield-of selected-user) item)))
(defunassert yadfa-bin:unwield (&key user)
    (user (or integer null))
  "Unwield an item. Set @var{USER} to the index of an ally to have them to unequip it or leave it @code{NIL} for the player."
  (let ((selected-user
          (if user
              (nth user (allies-of *game*))
              (player-of *game*))))
    (if (wield-of selected-user)
        (progn (push (wield-of selected-user)
                     (inventory-of (player-of *game*)))
               (setf (wield-of selected-user) nil))
        (format t "~a hasn't equiped a weapon~%" (name-of selected-user)))))
(defunassert yadfa-bin:pokedex (&optional enemy)
    (enemy symbol)
  "Browse enemies in your pokedex, @var{ENEMY} is a quoted symbol that is the same as the class name of the enemy you want to view. Leave it to @code{NIL} to list available entries"
  (if enemy
      (let ((a (if (s:memq enemy (seen-enemies-of *game*))
                   (make-instance enemy)
                   (progn (write-line "That enemy isn't in your pokedex")
                          (return-from yadfa-bin:pokedex)))))
        (format t "Name: ~a~%Species: ~a~%Description: ~a~%" (name-of a) (species-of a) (description-of a)))
      (progn (format t "~30a~30a~%" "ID" "Name")
             (iter (for i in (seen-enemies-of *game*))
               (let ((a (make-instance i)))
                 (format t "~30a~30a~%" i (name-of a)))))))
(defunassert yadfa-world:add-ally-to-team (ally-index)
    (ally-index unsigned-byte)
  "Adds an ally to your battle team. @var{ALLY-INDEX} is the index of an ally in your list of allies"
  (let ((allies-length (list-length (allies-of *game*))))
    (if (< allies-length ally-index)
        (format t "You only have ~d allies~%" allies-length)
        (pushnew (nth ally-index (allies-of *game*)) (team-of *game*)
                 :test (lambda (ally team-member)
                         (let ((result (eq ally team-member)))
                           (if result
                               (format t "~a is already on the battle team~%" (name-of ally))
                               (format t "~a has joined the battle team~%" (name-of ally)))
                           result))))))
(defunassert yadfa-world:remove-ally-from-team (team-index)
    (team-index unsigned-byte)
  "Removes an ally to your battle team. @var{TEAM-INDEX} is the index of an ally in your battle team list"
  (let ((team-length (list-length (team-of *game*))))
    (cond
      ((>= team-index team-length)
       (format t "You only have ~d members in your team~%" team-length)
       (return-from yadfa-world:remove-ally-from-team))
      ((eq (nth team-index (team-of *game*)) (player-of *game*))
       (write-line "You can't remove the player from the team")
       (return-from yadfa-world:remove-ally-from-team))
      (t (setf (team-of *game*) (remove-nth team-index (team-of *game*)))))))
(defunassert yadfa-world:swap-team-member (team-index-1 team-index-2)
    (team-index-1 unsigned-byte
                  team-index-2 unsigned-byte)
  "swap the positions of 2 battle team members. @var{TEAM-INDEX-1} and @var{TEAM-INDEX-2} are the index numbers of these members in your battle team list"
  (cond ((or (list-length-> team-index-1 (team-of *game*)) (list-length-> team-index-2 (team-of *game*)))
         (format t "You only have ~d members in your team~%" (list-length (team-of *game*)))
         (return-from yadfa-world:swap-team-member))
        ((= team-index-1 team-index-2)
         (write-line "Those refer to the same team member")
         (return-from yadfa-world:swap-team-member))
        (t (rotatef (nth team-index-1 (team-of *game*)) (nth team-index-2 (team-of *game*))))))
(defunassert yadfa-bin:toggle-lock (wear key &optional user)
    (wear unsigned-byte
          key unsigned-byte
          user (or unsigned-byte null))
  "Toggle the lock on one of the clothes a user is wearing. @var{WEAR} is the index of an item a user is wearing, @var{KEY} is the index of a key in your inventory, @var{USER} is a number that is the index of an ally, leave this to @code{NIL} to select the player."
  (let* ((selected-user (if user (nth user (allies-of *game*)) (player-of *game*)))
         (wear-length (list-length (wear-of selected-user)))
         (inventory-length (list-length (inventory-of (player-of *game*))))
         (selected-key (nth key (inventory-of (player-of *game*))))
         (selected-wear (nth wear (wear-of selected-user))))
    (cond ((not selected-user)
           (format t "You only have ~d allies~%" (list-length (allies-of *game*))))
          ((not (>= wear-length wear))
           (format t "~a is only wearing ~d items~%" (name-of selected-user) wear-length))
          ((not (>= inventory-length key))
           (format t "You only have ~d items in your inventory~%" inventory-length))
          ((not (typep selected-key (key-of selected-wear)))
           (write-line "That doesn't go with that"))
          ((lockedp selected-wear)
           (format t "~a's ~a is now unlocked~%" (name-of selected-user) (name-of selected-wear))
           (setf (lockedp selected-wear) nil))
          ((typep selected-wear 'closed-bottoms)
           (write-line "That can't be locked"))
          (t
           (format t "~a's ~a is now locked~%" (name-of selected-user) (name-of selected-wear))
           (setf (lockedp selected-wear) t)))))
