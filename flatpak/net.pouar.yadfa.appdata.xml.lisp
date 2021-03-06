(:!root
  ((:!header :version "1.0" :encoding "UTF-8"))
  (:!comment "Copyright 2018 Pouar Dragon")
  (application
    ((id :type "desktop") "net.pouar.yadfa.desktop")
    (name "Yadfa")
    (summary "Yet Another Diaperfur Adventure")
    (metadata_license "CC0-1.0")
    (update_contact "pouar@pouar.net")
    (categories
      (category "Game")
      (category "AdventureGame")
      (category "RolePlaying"))
    (releases
      ((release :version "0.9" :type "development" :date "2018-10-02")))
    ((content_rating :type "oars-1.1")
      ((content_attribute :id "violence-cartoon") "moderate")
      ((content_attribute :id "language-profanity") "intense")
      ((content_attribute :id "language-humor") "moderate")
      ((content_attribute :id "money-gambling") "moderate"))
    (screenshots
      ((screenshot :type "default")
        ((image :type "source") "https://www.pouar.net/downloads/yadfa-screenshot-1.png")))
    (project_license "GPL-3.0+")
    (developer_name "Pouar")
    (requires
      (memory 1024))
    ((launchable :type "desktop-id") "net.pouar.yadfa.desktop")
    (description "An experimental text based adventure you play by typing in Lisp code in a REPL")
    ((url :type "homepage") "https://cgit.pouar.net/yadfa.git/about")))
