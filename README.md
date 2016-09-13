# Game Prototype

Lightweight, minimal implementation of game mechanics for rapid experimentation and prototyping.

## Getting Started

You can load a sandbox console to launch a pry session to play with some of the main classes and query datasets from `./data/cycle-*.csv`:

```shell-session
$ bin/sandbox

From: /Users/tanner/LearnersGuild/game-prototype/bin/sandbox @ line 24 :

    19: ds = StatsFromData.new(gd)
    20: rs = ReviewStats.import(review_stat_files, 1000)
    21: ps = ProjectStats.import(proj_stat_files, 1000)
    22: s = Stats.new(ps, rs)
    23: sr = StatReporter.new(s)
 => 24: binding.pry

[1] pry(main)> s.projects(2)
=> ["absorbing-hedgehog",
 "cagey-lapwing",
 "clumsy-quail",
 "giant-viper",
 "measly-parakeet",
 "unusual-woodpecker"]
```

## Stats

To generate a stat report for the chapter, use the `./bin/stat-report-chapter` script.

_BEFORE YOU DO THIS_, you need to **prepare the data** (for projects and reviews). This is a four-step process:

1. Download the reflection data from the latest cycle (see [Data Sources](#data-sources)) and move to `./data/cycle-N.csv`, where `N` is the cycle number
1. Validate the data is appropriately formatted, and every active player logged their hours using `$ ./bin/validate-data ./data/cycle-N.csv`
1. Calculate stats **for each project** using the latest reflection data: `$ ./bin/project-stats ./data/cycle-N.csv`. This will add/update project stat files under `./stats/projects/`
1. Calculate new **review stats** using ALL the review data: `$ ./bin/review-stats ./data/cycle-*.csv`. This will update the `./stats/reviews.csv` file.

Now you are ready to generate a chapter stat report.

Stats can be generated for a chapter by running `./bin/stat-report-chapter` with a `CYCLE` env variable set to the cycle you wish to calculate stats up to.

The report will be written to a file `./reports/cycle1toN.csv` and printed `STDOUT`, and any missing data or errors will be written to `STDERR`.

```shell-session
$ CYCLE=4 bin/stat-report-chapter
  ...
$ cat reports/cycle-1to4.csv
id,xp,avg_cycle_hours,avg_proj_comp,avg_proj_qual,lrn_supp,cult_cont,team_play,est_accuracy,est_bias,no_proj_rvws
a4b6116a,22.78,40.0,89.28,90.0,83.33,83.33,MISSING DATA,MISSING DATA,MISSING DATA,8
cbcff678,53.24,36.25,82.94,83.29,70.0,93.33,MISSING DATA,90.5,-1.75,22
...
```

**Note**: this assumes the presence of a `./data/` directory with cycle data files and a `./reports/` directory for saving report files to. Both must be in the root folder.

### Elo Rating

To see Elo ratings for players, use the `bin/elo` command:

```shell-session
$ bin/elo data/cycle-*.csv
Elo rankings
------------
jrob8577            : 1159
thejaneofalltrades  : 1125
deadlyicon          : 1108
...
```

To see a history of all the Elo games, set the env variable `DEBUG` to `true`:

```shell-session
$ DEBUG=true bin/elo data/cycle-*.csv
 ---
Running games for cycle 1...
 ---
Running games for project depraved-malleefowl...
Team: Jusdev89, deadlyicon, shakalee14
Jusdev89(1000)      | deadlyicon(1400)    | 0.43                | Jusdev89(1067)      | deadlyicon(1332)    
Jusdev89(1067)      | shakalee14(1000)    | 0.49                | Jusdev89(1045)      | shakalee14(1021)    
...
```

### Anonymity

By default, all reports are generated without identifying player information (except for the shortened ID).

To turn anonymity off, and display player info like their name and GitHub handle, set the `ANON` env variable to `false`:

```shell-session
$ ANON=false bin/stat-report-player 75dbe257 data/cycle-1*
period,name,handle,id,xp,avg_proj_comp,avg_proj_qual,lrn_supp,cult_cont,est_accuracy,no_proj_rvws
aggregated stats,John Roberts,jrob8577,75dbe257,84.91,94.0,91.0,97.62,95.24,3.89,8
...
```

### Data Sources

The stats expect specifically formatted CSV files of game data. Download the game CSV data from `game.learnersguid.org`:

[https://game.learnersguild.org/reports/cycleResponses?chapterName=Oakland&cycleNumber=1](https://game.learnersguild.org/reports/cycleResponses?chapterName=Oakland&cycleNumber=1)

Change the `chapterName` and `cycleNumber` to match what you need.

Note: you'll need to have `moderator` or `backoffice` privileges to download these files.

Then move the cycle data files to a `./data/` directory (that way they aren't tracked by git).

### Validating Data

Sometimes the data will not be clean, which can make the stats wonky.

To validate game data, run `./bin/validate-data` and pass one or more data files:

```shell-session
$ bin/validate-data data/cycle-*.csv

[ERROR] Non-numeric hours: '... all of them... 9 hrs/day m-th and through noon on Friday... so around 40.'
 Record: {"cycleNumber"=>"3", "question"=>"During this past cycle, how many hours did you dedicate to this project?", "questionId"=>"29a4bc7e", "respondentEmail"=>"test@example.com",
...
```

It will highlight invalid or unparseable data in the files, so that you can fix them. ...which you'll have to do by hand. :)
