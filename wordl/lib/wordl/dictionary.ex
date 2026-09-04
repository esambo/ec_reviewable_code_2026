defmodule Wordl.Dictionary do
  @moduledoc """
  Five-letter Wordl vocabulary. Secret words are chosen from `@secrets`.
  Any five-letter alphabetic word is a valid player guess.
  """

  @secrets ~w(
    about above abuse actor acute admit adopt adult after again agent agree
    ahead alarm album alert alike alive allow alone along alter among anger
    angle angry apart apple apply arena argue arise array aside asset audio
    audit avoid award aware badly baker bases basic basis beach began begin
    begun being below bench billy birth black blame blind block blood board
    boost booth bound brain brand bread break breed brief bring broad broke
    brown build built buyer cable calif carry catch cause chain chair chart
    chase cheap check chest chief child china chose civil claim class clean
    clear click clock close cloud coach coast could count court cover craft
    crash cream crime cross crowd crown crude curve cycle daily dance dated
    dealt death debut delay depth doing doubt dozen draft drama drawn dream
    dress drill drink drive drove dying eager early earth eight elite empty
    enemy enjoy enter entry equal error event every exact exist extra faith
    false fault fiber field fifth fifty fight final first fixed flash fleet
    floor fluid focus force forth forty forum found frame frank fraud fresh
    front fruit fully funny giant given glass globe going grace grade grand
    grant grass grave great green gross group grown guard guess guest guide
    happy harry heart heavy hence horse hotel house human ideal image index
    inner input issue japan jimmy joint jones judge known label large laser
    later laugh layer learn least leave legal level light limit links lives
    local logic loose lower lucky lunch lying magic major maker march maria
    match maybe mayor meant media metal might minor minus mixed model money
    month moral motor mount mouse mouth movie music needs never newly night
    noise north noted novel nurse occur ocean offer often order other ought
    paint panel paper party peace peter phase phone photo piece pilot pitch
    place plain plane plant plate point pound power press price pride prime
    print prior prize proof proud prove queen quick quiet quite radio raise
    range rapid ratio reach ready refer right rival river robin roger roman
    rough round route royal rural scale scene scope score sense serve seven
    shall shape share sharp sheet shelf shell shift shirt shock shoot short
    shown sight since sixty skill sleep slide small smart smile smith smoke
    solid solve sorry space spare speak speed spend spent split spoke sport
    staff stage stake stand start state steam steel stick still stock stone
    stood store storm story strip stuck study stuff style sugar suite super
    sweet table taken taste taxes teach teeth terry thank theme there these
    thick thing think third those three threw throw tight times tired title
    today topic total touch tough tower track trade train treat trend trial
    tried truck truly trust truth twice under until upper upset urban usage
    usual valid value video virus visit vital voice waste watch water wheel
    where which while white whole whose woman world worry worse worst worth
    would wound write wrong wrote young youth
  )

  def secrets, do: @secrets

  def valid_guess?(word) when is_binary(word) do
    String.match?(String.downcase(word), ~r/^[a-z]{5}$/)
  end

  def random_secret(exclude \\ []) do
    exclude_set = MapSet.new(exclude)
    candidates = Enum.reject(@secrets, &MapSet.member?(exclude_set, &1))

    case candidates do
      [] -> Enum.random(@secrets)
      words -> Enum.random(words)
    end
  end
end
