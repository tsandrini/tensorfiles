# --- profiles/home-firefox/bookmarks.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'
[
  {
    toolbar = true;
    bookmarks = [
      # ~ Generic hotbookmarks
      {
        name = "";
        url = "https://www.novinky.cz/";
        keyword = "novinky";
      }
      {
        name = "";
        url = "https://www.root.cz/";
        keyword = "root";
      }
      {
        name = "";
        url = "http://osel.cz/";
        keyword = "osel";
      }
      {
        name = "";
        url = "https://www.theguardian.com/world";
        keyword = "theguardian";
      }
      {
        name = "";
        url = "https://www.aktualne.cz/";
        keyword = "aktualne";
      }
      {
        name = "Il Post";
        url = "https://www.ilpost.it/";
        keyword = "ilpost";
      }
      {
        name = "Il Post";
        url = "https://www.ilpost.it/";
        keyword = "ilpost";
      }
      {
        name = "ML";
        url = "https://www.reddit.com/r/MachineLearning/";
        keyword = "ml";
      }
      {
        name = "M";
        url = "https://monkeytype.com/";
        keyword = "monkeytype";
      }
      {
        name = "";
        url = "https://www.facebook.com/";
        keyword = "facebook";
      }
      {
        name = "";
        url = "https://is.cuni.cz/studium/index.php";
        keyword = "sis";
      }
      {
        name = "";
        url = "https://github.com/";
        keyword = "github";
      }
      {
        name = "";
        url = "https://gitlab.com/";
        keyword = "gitlab";
      }
      {
        name = "";
        url = "https://mynoise.net/";
        keyword = "mynoise";
      }
      {
        name = "";
        url = "https://pomofocus.io/";
        keyword = "pomofocus";
      }
      {
        name = "";
        url = "https://chat.openai.com/";
        keyword = "chatgpt";
      }
      {
        name = "Draw";
        url = "https://excalidraw.com/";
        keyword = "excalidraw";
      }
      # ~ Specific bookmarks
      {
        name = "/work/";
        bookmarks = [
          {
            name = "VRM Portal - Victron Energy";
            url = "https://vrm.victronenergy.com/";
          }
          {
            name = "Journal of Modern Power System and Clean Energy";
            url = "http://www.mpce.info/ch/index.aspx";
          }
          {
            name = "Journal of Modern Power System and Clean Energy";
            url = "https://ieeexplore.ieee.org/xpl/RecentIssue.jsp";
          }
        ];
      }
      # ~ /mff/
      {
        name = "/mff/";
        bookmarks = [
          {
            name = "Termodynamika a statistická fyzika I NTMF043";
            bookmarks = [
              {
                name = "Přemysl Kolorenč homepage";
                url = "http://utf.mff.cuni.cz/~kolorenc/#termodynamika";
              }
            ];
          }
          {
            name = "Geometrické metody teoretické fyziky I NTMF059";
            bookmarks = [
              {
                name = "NTMF059 - Geometrické metody teoretické fyziky I";
                url = "http://utf.mff.cuni.cz/vyuka/NTMF059/";
              }
              {
                name = "NTMF059 - materials for lectures at fall 2011";
                url = "http://utf.mff.cuni.cz/vyuka/NTMF059/2021/lectures9187.html";
              }
              {
                name = "NTMF059 - materiály k přednáškám v ZS 2020";
                url = "http://utf.mff.cuni.cz/vyuka/NTMF059/2020/prednasky3276.html";
              }
              {
                name = "NTMF059 - materiály k přednáškám v ZS 2020";
                url = "http://utf.mff.cuni.cz/vyuka/NTMF059/2020/prednasky3276.html";
              }
              {
                name = "Differential Geometry I Autumn 2017";
                url = "https://metaphor.ethz.ch/x/2017/hs/401-3531-00L/";
              }
            ];
          }
          {
            name = "Geometrické metody teoretické fyziky II NTMF060";
            bookmarks = [
              {
                name = "NTMF060 - Geometrické metody teoretické fyziky II";
                url = "http://utf.mff.cuni.cz/vyuka/NTMF060/";
              }
              {
                name = "NTMF060 - materials for the course in the spring term 2022";
                url = "http://utf.mff.cuni.cz/vyuka/NTMF060/2022/lectures5817.html#prednasky";
              }
              {
                name = "NTMF060 - materiály k přednáškám v LS 2021";
                url = "http://utf.mff.cuni.cz/vyuka/NTMF060/2021/prednasky4686.html";
              }
            ];
          }
          {
            name = "Kvantová teorie I NOFY076";
            bookmarks = [
              {
                name = "Kvantová mechanika";
                url = "https://www-ucjf.troja.mff.cuni.cz/cejnar/prednasky/qm.html";
              }
              {
                name = "Pavel Stránský - Cvičení k přednášce Kvantová teorie I";
                url = "http://www.pavelstransky.cz/cvicenikt1.php";
              }
            ];
          }
          {
            name = "Jaderná a částicová fyzika NOFY029";
            bookmarks = [
              {
                name = "Index of /~leitner/FyzikaV";
                url = "https://www-ucjf.troja.mff.cuni.cz/~leitner/FyzikaV/";
              }
            ];
          }
          {
            name = "Matematika pro fyziky II NOFY162";
            bookmarks = [
              {
                name = "https://www2.karlin.mff.cuni.cz/~dpokorny/";
                url = "https://www2.karlin.mff.cuni.cz/~dpokorny/";
              }
              {
                name = "https://www2.karlin.mff.cuni.cz/~dpokorny/NOFY162.htm";
                url = "https://www2.karlin.mff.cuni.cz/~dpokorny/NOFY162.htm";
              }
              {
                name = "Dalibor Smid, PhD. | Main / MATproFLS2122 browse";
                url = "https://www2.karlin.mff.cuni.cz/~smid/pmwiki/pmwiki.php?n=Main.MATproFLS2122";
              }
              {
                name = "Matematika pro fyziky NOFY162";
                url = "https://www2.karlin.mff.cuni.cz/~krump/analyza/";
              }
            ];
          }
          {
            name = "Klasická elektrodynamika NOFY126";
            bookmarks = [
              {
                name = "NOFY126 - Klasická elektrodynamika";
                url = "http://utf.mff.cuni.cz/vyuka/NOFY126/";
              }
              {
                name = "Tomáš_Ledvinka.Houmpejdž";
                url = "http://utf.mff.cuni.cz/~ledvinka/?278656";
              }
            ];
          }
          {
            name = "Úvod do kvantové mechaniky NOFY127";
            bookmarks = [
              {
                name = "Informační systémy / Videozáznamy přednášek";
                url = "https://is.mff.cuni.cz/prednasky/prednaska/NOFY027/1";
              }
              {
                name = "Tomáš Mančal: Úvod do kvantové teorie";
                url = "http://www.mancal.cz/en/vyuka/uvod-do-kvantove-teorie/";
              }
            ];
          }
          {
            name = "Mechanika kontinua NGEO111";
            bookmarks = [
              {
                name = "Ondřej Čadek";
                url = "http://geo.mff.cuni.cz/~cadek/";
              }
              {
                name = "Microsoft PowerPoint - hand01 - MK01.pdf";
                url = "http://geo.mff.cuni.cz/~oc/MK01.pdf";
              }
            ];
          }
          {
            name = "Hluboké učení NPFL114";
            bookmarks = [
              {
                name = "Deep Learning | ÚFAL";
                url = "https://ufal.mff.cuni.cz/courses/npfl114/2122-summer";
              }
              {
                name = "ufal/npfl114: Materials for the Deep Learning -- ÚFAL course NPFL114";
                url = "https://github.com/ufal/npfl114";
              }
              {
                name = "https://piazza.com/class/kzmwighamh26wd";
                url = "https://piazza.com/class/kzmwighamh26wd";
              }
              {
                name = "Equations of Motion for the Cart and Pole Control Task";
                url = "https://sharpneat.sourceforge.io/research/cart-pole/cart-pole-equations.html";
              }
              {
                name = "gradient-notes.pdf";
                url = "https://web.stanford.edu/class/cs224n/readings/gradient-notes.pdf";
              }
              {
                name = "Rademacher complexity - Wikipedia";
                url = "https://en.wikipedia.org/wiki/Rademacher_complexity";
              }
            ];
          }
          {
            name = "Výuka - Josef Málek";
            url = "https://www2.karlin.mff.cuni.cz/~malek/new/index.php?title=V%C3%BDuka";
          }
          {
            name = "Studijní plány (Karolínka), 2019/2020 – Bc. studium zahájené v roce 2019";
            url = "https://www.mff.cuni.cz/cs/studenti/bc-a-mgr-studium/studijni-plany/verze-pro-tisk/studijni-plany-karolinka-2019-2020-bc-studium.pdf";
          }
          {
            name = "Praktikum";
            url = "http://praktikum.brejlovec.net/index.php";
          }
          {
            name = "DISTANČNÍ výuka | Katedra tělesné výchovy";
            url = "https://ktv.mff.cuni.cz/distancni-vyuka/";
          }
          {
            name = "Základní fyzikální praktikum [Základní fyzikální praktikum]";
            url = "https://physics.mff.cuni.cz/vyuka/zfp/";
          }
        ];
      }
      # ~ /phil/
      {
        name = "/phil/";
        bookmarks = [
          {
            name = "Lubos Vins. Interpretace vybranych literarnich a filozofickych motivu v dile Franze Kafky.2013.pdf";
            url = "https://dspace5.zcu.cz/bitstream/11025/9735/1/Lubos%20Vins.%20Interpretace%20vybranych%20literarnich%20a%20filozofickych%20motivu%20v%20dile%20Franze%20Kafky.2013.pdf";
          }
        ];
      }
      # ~ /compsci/
      {
        name = "/compsci/";
        bookmarks = [
          {
            name = "DL";
            bookmarks = [
              {
                name = "Hugging Face – The AI community building the future.";
                url = "https://huggingface.co/";
              }
              {
                name = "Ceres Solver — A Large Scale Non-linear Optimization Library";
                url = "http://ceres-solver.org/";
              }
              {
                name = "pyraug/src/pyraug/models/rhvae at main · clementchadebec/pyraug";
                url = "https://github.com/clementchadebec/pyraug/blob/main/src/pyraug/models/rhvae/rhvae_model.py";
              }
              {
                name = "Davis Summarizes Papers | Davis Blalock | Substack";
                url = "https://dblalock.substack.com/";
              }
              {
                name = "The latest in Machine Learning | Papers With Code";
                url = "https://paperswithcode.com/";
              }
            ];
          }
          {
            name = "nix";
            bookmarks = [
              {
                name = "Awesome Nix | awesome-nix";
                url = "https://nix-community.github.io/awesome-nix/";
              }
              {
                name = "Hound";
                url = "https://search.nix.gsc.io/";
              }
            ];
          }
          {
            name = "Coursera | Online Courses & Credentials From Top Educators. Join for Free";
            url = "https://www.coursera.org/";
          }
          {
            name = "Pijul";
            url = "https://pijul.org/";
          }
          {
            name = "Welcome to nest.pijul.com";
            url = "https://nest.pijul.com/";
          }
          {
            name = "Qiskit";
            url = "https://qiskit.org/";
          }
          {
            name = "IHP: Integrated Haskell Platform, a batteries-included web framework built on purely functional programming technologies";
            url = "https://ihp.digitallyinduced.com/";
          }
          {
            name = "Lean";
            url = "https://leanprover.github.io/";
          }
        ];
      }
      # ~ /pol/
      {
        name = "/pol/";
        bookmarks = [
          {
            name = "Socialism101.com";
            url = "https://www.socialism101.com/";
          }
        ];
      }
      # ~ /buddhism/
      {
        name = "/buddhism/";
        bookmarks = [
          {
            name = "Meditační centrum Praha";
            url = "http://www.mcpraha.org/cz";
          }
        ];
      }
      # ~ /ling/
      {
        name = "/ling/";
        bookmarks = [
          {
            name = "latin";
            bookmarks = [
              {
                name = "Latin by the Ranieri-Dowling Method | Latin Grammar, Latin Cases, Latin Declension Chart - YouTube";
                url = "https://www.youtube.com/watch?v=_yflqUWKVVc";
              }
            ];
          }
          {
            name = "vietnamese";
            bookmarks = [
              {
                name = "best way to learn vietnamese and resources? : languagelearning";
                url = "https://www.reddit.com/r/languagelearning/comments/920gm2/best_way_to_learn_vietnamese_and_resources/";
              }
              {
                name = "Memrise - Vietnamese - Courses for English (UK) speakers";
                url = "https://app.memrise.com/courses/english/vietnamese/";
              }
            ];
          }
        ];
      }
      # ~ /tea/
      {
        name = "/tea/";
        bookmarks = [
          {
            name = "Hunan Tian Jian Tea — Yunnan Sourcing Tea Shop";
            url = "https://yunnansourcing.com/collections/hunan-tian-jian-tea";
          }
        ];
      }
      # ~ /osu/
      {
        name = "/osu/";
        bookmarks = [
          {
            name = "stats";
            bookmarks = [
              {
                name = "not_a_name_old_1 | osu!Skills";
                url = "https://osuskills.com/user/not_a_name_old_1";
              }
              {
                name = "not_a_name_old_1's profile";
                url = "https://osudaily.net/profile.php?u=37529";
              }
              {
                name = "User Statistics for not_a_name_old_1";
                url = "https://ameobea.me/osutrack/user/not_a_name_old_1/";
              }
              {
                name = "not_a_name_old_1's Profile";
                url = "https://osutracker.com/user/30684398";
              }
            ];
          }
          {
            name = "Tillerino/Tillerinobot";
            url = "https://github.com/Tillerino/Tillerinobot";
          }
        ];
      }
      # ~ /astro/
      {
        name = "/astro/";
        bookmarks = [
          {
            name = "Horoskopy.cz";
            url = "https://www.horoskopy.cz/";
          }
          {
            name = "Animal Spirits - The Daily Animal Spirit | Astrology.com.au";
            url = "https://astrology.com.au/psychic-readings/oracles/animal-spirits/dailyspirit";
          }
        ];
      }
      # ~ /misc/
      {
        name = "/misc/";
        bookmarks = [
          {
            name = "jaakkopasanen/AutoEq: Automatic headphone equalization from frequency responses";
            url = "https://github.com/jaakkopasanen/AutoEq";
          }
          {
            name = "DIY Huaraches Sandalen - Barfußschuhe - YouTube";
            url = "https://www.youtube.com/watch?v=kHV3em_wGhI";
          }
        ];
      }
    ];
  }
]
