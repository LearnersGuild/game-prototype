# Game Prototype

Lightweight, minimal implementation of game mechanics for rapid experimentation and prototyping.

## Stats

First, go download the retro CSV data from `game.learnersguid.org`:

[https://game.learnersguild.org/reports/cycleResponses?chapterName=Oakland&cycleNumber=1](https://game.learnersguild.org/reports/cycleResponses?chapterName=Oakland&cycleNumber=1)

Change the `chapterName` and `cycleNumber` to match what you need.

Note: you'll need to have `moderator` or `backoffice` privileges to download these files.

Then move the cycle data files to the `data/` directory (that way they aren't tracked by git).

Now you can create specs for one or more cycles:

```shell-session
$ bin/stat-report-chapter data/cycle-1.csv data/cycle-2.csv > stats.csv
$ cat stats.csv
id,name,handle,xp,proj-completeness,proj-quality,rel-contribution
af38nda2,bob jones,bobbyj,123,98.23,72.23,3.42
...

$ bin/stat-report-player af38nda2 data/cycle-1.csv data/cycle-2.csv > stats.csv
$ cat stats.csv
id,name,handle,xp,proj-completeness,proj-quality,rel-contribution
af38nda2,bob jones,bobbyj,123,98.23,72.23,3.42
```
