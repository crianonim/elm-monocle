module PrismSpec (all) where

import ElmTest exposing (suite, equals, Test)
import Check exposing (that, is, for, claim, check)
import Check.Test exposing (test, assert)
import Check.Investigator exposing (Investigator, tuple, string, list, char, int)
import Random exposing (initialSeed)
import Random.Int
import Random.Extra exposing (constant)
import Shrink
import String
import Char
import Maybe
import Result


--import Monocle.Iso exposing (Iso)

import Monocle.Prism exposing (Prism)


all : Test
all =
    suite
        "A Prism specification"
        [ test_prism_property_partial_round_trip_one_way
        , test_prism_property_no_round_trip_when_not_matching
        , test_prism_property_round_trip_other_way
        , test_prism_method_modify
        , test_prism_method_compose
        ]


count : Int
count =
    100


seed : Random.Seed
seed =
    initialSeed 21882981


digits =
    Check.Investigator.investigator (Random.Int.intLessThan 10000000 |> Random.map (abs >> toString)) Shrink.string


string2IntPrism : Prism String Int
string2IntPrism =
    Prism (String.toInt >> Result.toMaybe) toString


string2FloatPrism : Prism String Float
string2FloatPrism =
    Prism (String.toFloat >> Result.toMaybe) toString


float2IntPrism : Prism Float Int
float2IntPrism =
    let
        getOption float =
            let
                int = truncate float

                back = toFloat int
            in
                if (float == back) then
                    Just int
                else
                    Nothing
    in
        Prism getOption toFloat


test_prism_property_partial_round_trip_one_way =
    let
        prism = string2IntPrism

        actual x = x |> prism.getOption |> Maybe.map prism.reverseGet

        expected x = Just x

        investigator = digits
    in
        test "For some a: A, getOption a |> Maybe.map reverseGet == Just a" actual expected investigator count seed


test_prism_property_no_round_trip_when_not_matching =
    let
        prism = string2IntPrism

        actual x = x |> prism.getOption |> Maybe.map prism.reverseGet

        expected x = Nothing

        investigator = string
    in
        test "For some a: A, getOption a |> Maybe.map reverseGet == Nothing " actual expected investigator count seed


test_prism_property_round_trip_other_way =
    let
        prism = string2IntPrism

        actual x = x |> prism.reverseGet >> prism.getOption

        expected x = Just x

        investigator = int
    in
        test "For all a: A, getOption (reverseGet a) == Just a " actual expected investigator count seed


test_prism_method_modify =
    let
        prism = string2IntPrism

        actual x =
            let
                fx i = i * 2

                modified = Monocle.Prism.modify prism fx
            in
                modified x

        expected x = x |> String.toInt >> Result.toMaybe >> Maybe.map ((*) 2 >> toString) |> Maybe.withDefault ""

        investigator = digits
    in
        test "Prism.modify" actual expected investigator count seed


test_prism_method_compose =
    let
        prism = Monocle.Prism.compose string2FloatPrism float2IntPrism

        actual x = prism.getOption x

        expected x = x |> String.toInt >> Result.toMaybe

        investigator = string
    in
        test "Iso.compose" actual expected investigator count seed
