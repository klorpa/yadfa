;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa-items"; coding: utf-8-unix; -*-
(in-package :yadfa-items)
(defclass gold-bar (item) ()
  (:default-initargs
   :name "Gold Bar"
   :description "A Gold Bar"
   :value 50000))
(defclass gem (item) ()
  (:default-initargs
   :name "Gem"
   :description "A Valuable Gem"
   :value 25000))
(defclass gold-collar (headpiece) ()
  (:default-initargs
   :name "Gold Collar"
   :description "A very expensive collar with a gold tag and studded with gems"
   :value 25000))
(defclass collar (headpiece) ()
  (:default-initargs
   :name "Collar"
   :description "A collar that your pet furries can wear. Has an id tag on it for easy identification."))
(defclass magic-diaper-key (item) ()
  (:default-initargs
   :name "Magic Diaper Key"
   :tossable nil
   :sellable nil
   :description "This mysterious artifact seems to have the ability to prevent others from removing their diapers"))
(defclass pocket-map-machine (item) ()
  (:default-initargs
   :name "Pocket Map Machine"
   :tossable nil
   :sellable nil
   :description "So you're playing Pokémon and you're making your secret base. Then you're like “Damn, I wish I could take this awesome base with me” or “I wish I could create my own decorations for this base instead of only being able to use what Nintendo provides me”. While Pouar can't do anything about Pokémon, he can create a similar feature for this game without these limitations. So here it is, the Pocket Map Machine"))
(defmethod use-script ((item pocket-map-machine) (user base-character) (target base-character))
  (declare (ignore user))
  (move-to-pocket-map item))
(defclass warp-device (item) ()
  (:default-initargs
   :name "Warp Device"
   :tossable nil
   :sellable nil
   :description "This device can be used to summon a warp pipe to take you to the secret underground"))
(defmethod use-script ((item warp-device) (user base-character) (target base-character))
  (declare (ignore item user target))
  (move-to-secret-underground))
(defclass macguffin (item) ()
  (:default-initargs
   :name "MacGuffin"
   :sellable nil
   :tossable nil
   :description "Collect as many of these fuckers as you possibly can. Don't ask why, just do it."))
(defclass itemfinder (item) ()
  (:default-initargs
   :name "Itemfinder"
   :description "Returns T anytime a hidden item is nearby. It is based on Pouar's ability to detect whatever he has to say is offensive or not. It uses the same algorithm, is about as effective, and has about as many happy customers. Also, if you wrap the function in a not function, it becomes the same algorithm SJWs use to decide whatever they hear is offensive or not."))
(defmethod use-script ((item itemfinder) (user base-character) (target base-character))
  (declare (ignore item user target)))
(defclass shine-star (item) ()
  (:default-initargs
   :name "Shine Star"
   :sellable nil
   :tossable nil
   :description "Collect as many of these fuckers as you possibly can. Don't ask why, just do it."))
(defclass enemy-catcher (item)
  ((contained-enemies%
    :initarg contained-enemies
    :accessor contained-enemies-of
    :initform nil
    :type list
    :documentation "list that contains the caught enemies")
   (contained-enemies-max-length%
    :initarg contained-enemies-max-length
    :accessor contained-enemies-max-length-of
    :initform 1
    :type unsigned-byte
    :documentation "Maximum amount of enemies this can hold")
   (catch-chance-multiplier%
    :initarg catch-chance-multiplier
    :accessor catch-chance-multiplier-of
    :initform 1
    :type (real 0)
    :documentation "Multiplier of the chance this item might catch an enemy")
   (catch-chance-delta%
    :initarg catch-chance-delta
    :accessor catch-chance-delta-of
    :initform 0
    :type real
    :documentation "How much of an increase this item might catch an enemy. if the multiplier is also specified, then this gets multiplied too")
   (device-health%
    :initarg device-health
    :accessor device-health-of
    :initform 1
    :type (or unsigned-byte null)
    :documentation "How many times it can fail to catch the enemy before it gets destroyed. @code{T} means it never gets destroyed")
   (max-device-health%
    :initarg max-device-health
    :accessor max-device-health-of
    :initform 1
    :type (or unsigned-byte null)
    :documentation "The maximum amount of @var{DEVICE-HEALTH} this item has. @code{T} means it never gets destroyed"))
  (:default-initargs
   :name "Enemy Catcher"
   :description "Use this to catch enemies"
   :value 500
   :power 0))
(s:defmethods enemy-catcher (item)
  (:method cant-use-p (item (user base-character) (target base-character) action &key &allow-other-keys)
    (values t `(:format-control "~a can't be used on ~a" :format-arguments `(,(name-of item) ,(name-of target)))))
  (:method cant-use-p (item (user base-character) (target yadfa-enemies:catchable-enemy) action &key &allow-other-keys)
    nil))
(defclass ghost-catcher (enemy-catcher) ()
  (:default-initargs
   :name "Ghost Catcher"
   :description "Use this to catch ghosts"))
;;; actual class isn't loaded yet, but methods need a class defined, so define a dummy class
;;; which should get replaced later in the loading process
(unless (find-class 'yadfa-enemies:ghost nil)
  (defclass yadfa-enemies:ghost () ()))
(s:defmethods ghost-catcher (item)
  (:method cant-use-p (item (user base-character) (target base-character) action &key &allow-other-keys)
    (values t `(:format-control "~a can't be used on ~a" :format-arguments `(,(name-of item) ,(name-of target)))))
  (:method cant-use-p (item (user base-character) (target yadfa-enemies:ghost) action &key &allow-other-keys)
    nil))
