module ParseType
  ( type_
  , possibleFunc
  )
where

import ParseUtils

import Data.Text (Text)

import qualified Syntax as Stx
import ParseIdent (keyword, escapable, path, typeIdent', typeVarIdent')

atom :: Parser Stx.Type
atom = Stx.TypeAtom <$> (Stx.Path <$> path <*> escapable typeIdent')

var :: Parser Stx.Type
var = Stx.TypeVar <$> escapable typeVarIdent'

parenthesized :: Parser Stx.Type
parenthesized = char '(' *> spaces *> option Stx.TypeUnit type_ <* spaces <* char ')'

atomicType :: Parser Stx.Type
atomicType =
  choice
    [ parenthesized
    , keyword "Pure" *> pure Stx.TypePure
    , keyword "Never" *> pure Stx.TypeNever
    , atom
    , var
    ]

apps :: Parser Stx.Type
apps =
  foldl Stx.TypeApp
    <$> (atomicType <* spaces)
    <*> many (char '<' *> spaces *> type_ <* spaces <* char '>' <* spaces)

possibleInters :: Parser Stx.Type
possibleInters =
  foldl1 Stx.TypeInters <$> sepBy1 (apps <* spaces) (char '|' *> spaces)

assemblePossibleFunc :: Stx.Type -> Maybe (Stx.Type, Stx.Type) -> Stx.Type
assemblePossibleFunc t Nothing = t
assemblePossibleFunc arg (Just (inters, ret)) = Stx.TypeFunc arg inters ret

possibleFunc :: Parser Stx.Type
possibleFunc =
  assemblePossibleFunc
    <$> (possibleInters <* spaces)
    <*> optionMaybe (
      (,)
      <$> option Stx.TypePure (char '!' *> spaces *> possibleInters <* spaces)
      <*> (string "->" *> spaces *> possibleFunc)
    )

possibleTuple :: Parser Stx.Type
possibleTuple =
  foldr1 Stx.TypeTuple <$> sepBy1 (possibleFunc <* spaces) (char ',' <* spaces)

type_ :: Parser Stx.Type
type_ = possibleTuple