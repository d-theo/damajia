module RandomUtils exposing (fiveLetterEnglishWord)
import Random.String
import Random.Char
import Random

fiveLetterEnglishWord = Random.String.string 5 Random.Char.english