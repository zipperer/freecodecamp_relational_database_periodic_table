if [[ -z $1 ]]
then
  echo 'Please provide an element as an argument.'
  exit
fi

PSQL="psql --username=freecodecamp --dbname=periodic_table -t --no-align -c"

FAILED_TO_FIND_ELEMENT=false

LOOKUP_ATOMIC_NUMBER_INFO_AND_PRINT () {
  ELEMENT_ATOMIC_NUMBER=$1
  ELEMENT_NAME=$2
  ELEMENT_SYMBOL=$3
  ATOMIC_NUMBER_ELEMENT_INFO=$($PSQL "SELECT atomic_mass, melting_point_celsius, boiling_point_celsius, type_id FROM properties WHERE atomic_number = $ELEMENT_ATOMIC_NUMBER")
  if [[ -z $ATOMIC_NUMBER_ELEMENT_INFO ]]
  then
    echo 'no atomic number element info'
    FAILED_TO_FIND_ELEMENT=true
  else
    echo "$ATOMIC_NUMBER_ELEMENT_INFO" | while IFS='|' read ELEMENT_ATOMIC_MASS_SQL_RESULT ELEMENT_MELTING_POINT_SQL_RESULT ELEMENT_BOILING_POINT_SQL_RESULT ELEMENT_TYPE_ID_SQL_RESULT
    do
      #echo 'found atomic element info'
      #echo '$ELEMENT_TYPE_ID_SQL_RESULT' $ELEMENT_TYPE_ID_SQL_RESULT
      ELEMENT_TYPE_ID=$ELEMENT_TYPE_ID_SQL_RESULT
      ELEMENT_ATOMIC_MASS=$ELEMENT_ATOMIC_MASS_SQL_RESULT
      ELEMENT_BOILING_POINT=$ELEMENT_BOILING_POINT_SQL_RESULT
      ELEMENT_MELTING_POINT=$ELEMENT_MELTING_POINT_SQL_RESULT
      if [[ -z $ELEMENT_TYPE_ID ]]
      then
        echo 'failed to find element type id'
      else
        ELEMENT_TYPE_SQL_RESULT=$($PSQL "SELECT type FROM types WHERE type_id = $ELEMENT_TYPE_ID")
        ELEMENT_TYPE=$ELEMENT_TYPE_SQL_RESULT
      fi
      echo "The element with atomic number $ELEMENT_ATOMIC_NUMBER is $ELEMENT_NAME ($ELEMENT_SYMBOL). It's a $ELEMENT_TYPE, with a mass of $ELEMENT_ATOMIC_MASS amu. $ELEMENT_NAME has a melting point of $ELEMENT_MELTING_POINT celsius and a boiling point of $ELEMENT_BOILING_POINT celsius."
      exit
    done
  fi
}

ATTEMPT_TO_INTERPRET_INPUT_AS_ATOMIC_NUMBER () {
  if [[ $1 =~ ^[0-9]+$ ]]
  then
    # interpret input as atomic_number                                                                                   
    ELEMENT_ATOMIC_NUMBER=$1
    # attempt to get info by atomic number                                                                               
    ATOMIC_NUMBER_ELEMENT_SYMBOL_NAME=$($PSQL "SELECT symbol, name FROM elements WHERE atomic_number = $ELEMENT_ATOMIC_NUMBER")
    if [[ -z $ATOMIC_NUMBER_ELEMENT_SYMBOL_NAME ]]
    then
      FAILED_TO_FIND_ELEMENT=true
    else
      #echo '"$ATOMIC_NUMBER_ELEMENT_SYMBOL_NAME"' "$ATOMIC_NUMBER_ELEMENT_SYMBOL_NAME"
      echo "$ATOMIC_NUMBER_ELEMENT_SYMBOL_NAME" | while IFS='|' read ELEMENT_SYMBOL_SQL_RESULT ELEMENT_NAME_SQL_RESULT
      do
        #echo '$ELEMENT_SYMBOL_SQL_RESULT' $ELEMENT_SYMBOL_SQL_RESULT
        #echo '$ELEMENT_NAME_SQL_RESULT' $ELEMENT_NAME_SQL_RESULT
        ELEMENT_SYMBOL=$ELEMENT_SYMBOL_SQL_RESULT
        ELEMENT_NAME=$ELEMENT_NAME_SQL_RESULT
        LOOKUP_ATOMIC_NUMBER_INFO_AND_PRINT $ELEMENT_ATOMIC_NUMBER $ELEMENT_NAME $ELEMENT_SYMBOL
      done
    fi
  fi
}

FAILED_TO_INTERPRET_INPUT_AS_ATOMIC_NAME=false

ATTEMPT_TO_INTERPRET_INPUT_AS_ATOMIC_NAME () {
  if [[ $1 =~ ^[a-zA-Z]+$ ]]
  then
    ELEMENT_NAME=$1
    ELEMENT_NAME_INFO=$($PSQL "SELECT atomic_number, symbol FROM elements WHERE name = '$ELEMENT_NAME'")
    if [[ -z $ELEMENT_NAME_INFO ]]
    then
      FAILED_TO_INTERPRET_INPUT_AS_ATOMIC_NAME=true
    else
      echo "$ELEMENT_NAME_INFO" | while IFS='|' read ELEMENT_ATOMIC_NUMBER ELEMENT_SYMBOL
      do
        LOOKUP_ATOMIC_NUMBER_INFO_AND_PRINT $ELEMENT_ATOMIC_NUMBER $ELEMENT_NAME $ELEMENT_SYMBOL
      done
    fi
  fi  
}

FAILED_TO_INTERPRET_INPUT_AS_ATOMIC_SYMBOL=false

ATTEMPT_TO_INTERPRET_INPUT_AS_ATOMIC_SYMBOL () {
  if [[ $1 =~ ^[a-zA-Z]+$ ]]
  then
    ELEMENT_SYMBOL=$1
    ELEMENT_SYMBOL_INFO=$($PSQL "SELECT atomic_number, name FROM elements WHERE symbol = '$ELEMENT_SYMBOL'")
    if [[ -z $ELEMENT_SYMBOL_INFO ]]
    then
      FAILED_TO_INTERPRET_INPUT_AS_ATOMIC_SYMBOL=true
    else
      echo "$ELEMENT_SYMBOL_INFO" | while IFS='|' read ELEMENT_ATOMIC_NUMBER ELEMENT_NAME
      do
        LOOKUP_ATOMIC_NUMBER_INFO_AND_PRINT $ELEMENT_ATOMIC_NUMBER $ELEMENT_NAME $ELEMENT_SYMBOL
      done
    fi
  fi
}

ATTEMPT_TO_INTERPRET_INPUT_AS_ATOMIC_NUMBER $1
ATTEMPT_TO_INTERPRET_INPUT_AS_ATOMIC_NAME $1
ATTEMPT_TO_INTERPRET_INPUT_AS_ATOMIC_SYMBOL $1

if [[ ($FAILED_TO_INTERPRET_INPUT_AS_ATOMIC_SYMBOL == 'true') && ($FAILED_TO_INTERPRET_INPUT_AS_ATOMIC_NAME == 'true') ]]
then
  FAILED_TO_FIND_ELEMENT=true
fi

if [[ $FAILED_TO_FIND_ELEMENT == 'true' ]]
then
  echo 'I could not find that element in the database.'
  exit
fi
