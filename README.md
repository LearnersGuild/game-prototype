# Game Prototype

Lightweight, minimal implementation of game mechanics for rapid experimentation and prototyping.

## Quick (sorta) and Dirty Stat Calculation

For all following, assume that `N` is the cycle number to calculate stats for. `N` should be an integer greater than 1.

1. Download the retro/review data at `https://game.learnersguild.org/reports/cycleResponses?chapterName=Oakland&cycleNumber=N`
1. Move the downloaded file to the `./data/` folder

  `$ mv ~/path/to/cycleResponses.csv ./data/`
1. Calculate all stats

  `$ CYCLE=N ./bin/run`
1. Open the generated cycle stats file

  `$ open stats/cycle-N.csv`
1. Copy the stats over into a new sheet on the [Player Stats [READ ONLY]](https://docs.google.com/spreadsheets/d/1OeEsKJIz86NArRsdlzJ6qVhxzQwfmdm2yoFdoxguiuw/edit#gid=1404536392) spreadsheet
  - To preserve formatting, duplicate an existing `cycle1toX` sheet first
1. Create a new `Cycle N Progress` sheet on the [Player Stats [READ ONLY]](https://docs.google.com/spreadsheets/d/1OeEsKJIz86NArRsdlzJ6qVhxzQwfmdm2yoFdoxguiuw/edit#gid=1404536392) spreadsheet
  - To preserve formatting and formulas, duplicate an existing `Cycle X Progress` sheet first
1. Change the formulas in `Cycle N Progress` to show diff between cycle N and N-1.
1. Share with player support

### Errors from missing stats

Sometimes there aren't retros submitted for all members of a project. This breaks the stats. :(

To get around this, run the `bin/run` script with an `OMIT` env variable set to a list of the project names, separated by a comma.

For example, in cycle 18 we had to calculate stats like this:

```
$ CYCLE=18 OMIT=disturbed-grison,ablaze-coot bin/run
```

Because there were retros missing for #disturbed-grison and #ablaze-coot.

If you want to check for potential errors _before_ running `bin/run`, use `bin/validate-data $DATA_FILE`, e.g.:

```
$ bin/validate-data data/cycle-18.csv
Validated hours. 0 invalid record(s) found.
Checked project reviews. 0 projects are missing reviews.
[MISSING DATA] No hours reported for full team of: 'disturbed-grison'
  Cycle: 18 IDs: ["b7faca92-1701-4895-a455-27fcf50fc838"]
[MISSING DATA] No hours reported for full team of: 'ablaze-coot'
  Cycle: 18 IDs: ["0af92c55-918e-43df-8014-efa35f18dd7d"]
Checked project hours. 2 projects are missing hours.
```

## Exploring

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

The report will be written to a file `./reports/cycleN.csv` and printed `STDOUT`, and any missing data or errors will be written to `STDERR`.

```shell-session
$ CYCLE=4 bin/stat-report-chapter
  ...
$ cat reports/cycle-4.csv
id,xp,avg_cycle_hours,avg_proj_comp,avg_proj_qual,lrn_supp,cult_cont,team_play,est_accuracy,est_bias,no_proj_rvws
a4b6116a,22.78,40.0,89.28,90.0,83.33,83.33,MISSING DATA,MISSING DATA,MISSING DATA,8
cbcff678,53.24,36.25,82.94,83.29,70.0,93.33,MISSING DATA,90.5,-1.75,22
...
```

**Note**: this assumes the presence of a `./data/` directory with cycle data files and a `./stats/` directory for saving stat report files to.

### Elo Rating

To see Elo ratings for players, use the `bin/elo` command:

```shell-session
$ CYCLE=17 bin/elo
Elo rankings
------------
jrob8577            : 1159
thejaneofalltrades  : 1125
deadlyicon          : 1108
...
```

To see a history of all the Elo games, set the env variable `DEBUG` to `true`:

```shell-session
$ DEBUG=true CYCLE=17 bin/elo
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

Then move the cycle data files to the `./data/` directory.

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
