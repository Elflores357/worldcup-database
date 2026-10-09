#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

declare -A seen_teams
team_values=""
game_values=""

while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
  [[ $year == "year" ]] && continue

  for team in "$winner" "$opponent"
  do
    if [[ -z ${seen_teams[$team]} ]]
    then
      seen_teams[$team]=1
      team_values+="('$team'),"
    fi
  done

  game_values+="($year, '$round', '$winner', '$opponent', $winner_goals, $opponent_goals),"
done < games.csv

$PSQL "INSERT INTO teams(name) VALUES ${team_values%,} ON CONFLICT (name) DO NOTHING" > /dev/null
$PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) SELECT game_data.year, game_data.round, winner.team_id, opponent.team_id, game_data.winner_goals, game_data.opponent_goals FROM (VALUES ${game_values%,}) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals) JOIN teams AS winner ON winner.name = game_data.winner JOIN teams AS opponent ON opponent.name = game_data.opponent" > /dev/null
