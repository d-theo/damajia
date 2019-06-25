module Model exposing (Model, init)
import Page exposing (Page(..))
import Msg exposing(Msg(..))
import Page.Settings exposing (Model)

type alias AppConfig =
  { api_url : String
  }

type alias Model = 
  { page: Page
  , global: String
  , appConfig: AppConfig
  }


init : AppConfig -> ( Model, Cmd Msg )
init config = (
  { page = SettingsPage { gameId = "", timeout = 30, numberOfQuestions = 10, gameToJoin = ""}
  , global = ""
  , appConfig = {api_url = ""}
  }
  , Cmd.batch []
  )
  