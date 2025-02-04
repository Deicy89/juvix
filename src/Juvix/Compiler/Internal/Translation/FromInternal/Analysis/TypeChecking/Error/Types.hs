module Juvix.Compiler.Internal.Translation.FromInternal.Analysis.TypeChecking.Error.Types where

import Juvix.Compiler.Internal.Language
import Juvix.Compiler.Internal.Pretty (fromGenericOptions)
import Juvix.Compiler.Internal.Translation.FromInternal.Analysis.TypeChecking.Error.Pretty
import Juvix.Data.PPOutput
import Juvix.Prelude

-- | the type of the constructor used in a pattern does
-- not match the type of the inductive being matched
data WrongConstructorType = WrongConstructorType
  { _wrongCtorTypeName :: Name,
    _wrongCtorTypeExpected :: InductiveName,
    _wrongCtorTypeActual :: InductiveName
  }

makeLenses ''WrongConstructorType

instance ToGenericError WrongConstructorType where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = i,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i]
            }
        where
          opts' = fromGenericOptions opts
          ctorName = e ^. wrongCtorTypeName
          i = getLoc ctorName
          msg =
            "The constructor"
              <+> ppCode opts' ctorName
              <+> "belongs to the inductive type:"
                <> line
                <> indent' (ppCode opts' (e ^. wrongCtorTypeActual))
                <> line
                <> "but is expected to belong to the inductive type:"
                <> line
                <> indent' (ppCode opts' (e ^. wrongCtorTypeExpected))

data WrongReturnType = WrongReturnType
  { _wrongReturnTypeConstructorName :: Name,
    _wrongReturnTypeExpected :: Expression,
    _wrongReturnTypeActual :: Expression
  }

makeLenses ''WrongReturnType

instance ToGenericError WrongReturnType where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = j,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i, j]
            }
        where
          opts' = fromGenericOptions opts
          ctorName = e ^. wrongReturnTypeConstructorName
          i = getLoc ctorName
          ty = e ^. wrongReturnTypeActual
          j = getLoc ty
          msg =
            "The constructor"
              <+> ppCode opts' ctorName
              <+> "has the wrong return type:"
                <> line
                <> indent' (ppCode opts' ty)
                <> line
                <> "but is expected to have type:"
                <> line
                <> indent' (ppCode opts' (e ^. wrongReturnTypeExpected))

newtype UnsolvedMeta = UnsolvedMeta
  { _unsolvedMeta :: Hole
  }

makeLenses ''UnsolvedMeta

instance ToGenericError UnsolvedMeta where
  genericError e =
    return
      GenericError
        { _genericErrorLoc = i,
          _genericErrorMessage = ppOutput msg,
          _genericErrorIntervals = [i]
        }
    where
      i = getLoc (e ^. unsolvedMeta)
      msg :: Doc a
      msg = "Unable to infer the hole"

-- | The arguments of a constructor pattern do not match
-- the expected arguments of the constructor
data WrongConstructorAppArgs = WrongConstructorAppArgs
  { _wrongCtorAppApp :: ConstructorApp,
    _wrongCtorAppTypes :: [FunctionParameter],
    _wrongCtorAppName :: Name
  }

makeLenses ''WrongConstructorAppArgs

instance ToGenericError WrongConstructorAppArgs where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = i,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i]
            }
        where
          opts' = fromGenericOptions opts
          i = getLoc (e ^. wrongCtorAppApp . constrAppConstructor)
          msg =
            "The constructor:"
              <+> ctorName
              <+> "is being matched against"
              <+> numPats
                <> ":"
                <> line
                <> indent' (ppCode opts' (e ^. wrongCtorAppApp))
                <> line
                <> "but is expected to be matched against"
              <+> numTypes
              <+> "with the following types:"
                <> line
                <> indent' (hsep (ctorName : (ppCode opts' <$> (e ^. wrongCtorAppTypes))))
          numPats :: Doc ann
          numPats = pat (length (e ^. wrongCtorAppApp . constrAppParameters))
          numTypes :: Doc ann
          numTypes = pat (length (e ^. wrongCtorAppTypes))

          ctorName :: Doc Ann
          ctorName = ppCode opts' (e ^. wrongCtorAppApp . constrAppConstructor)

          pat :: Int -> Doc ann
          pat n = pretty n <+> plural "pattern" "patterns" n

-- | the type of an expression does not match the inferred type
data WrongType = WrongType
  { _wrongTypeThing :: Either Expression Pattern,
    _wrongTypeExpected :: Expression,
    _wrongTypeActual :: Expression
  }

makeLenses ''WrongType

instance ToGenericError WrongType where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = i,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i]
            }
        where
          opts' = fromGenericOptions opts
          i = either getLoc getLoc (e ^. wrongTypeThing)
          msg =
            "The"
              <+> thing
              <+> either (ppCode opts') (ppCode opts') subjectThing
              <+> "has type:"
                <> line
                <> indent' (ppCode opts' (e ^. wrongTypeActual))
                <> line
                <> "but is expected to have type:"
                <> line
                <> indent' (ppCode opts' (e ^. wrongTypeExpected))
          thing :: Doc a
          thing = case subjectThing of
            Left {} -> "expression"
            Right {} -> "pattern"
          subjectThing :: Either Expression Pattern
          subjectThing = e ^. wrongTypeThing

-- | The left hand expression of a function application is not
-- a function type.
data ExpectedFunctionType = ExpectedFunctionType
  { _expectedFunctionTypeExpression :: Expression,
    _expectedFunctionTypeApp :: Expression,
    _expectedFunctionTypeType :: Expression
  }

makeLenses ''ExpectedFunctionType

instance ToGenericError ExpectedFunctionType where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = i,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i]
            }
        where
          opts' = fromGenericOptions opts
          i = getLoc (e ^. expectedFunctionTypeExpression)
          msg =
            "Type error near"
              <+> pretty (getLoc subjectExpr)
                <> "."
                <> line
                <> "In the expression:"
                <> line
                <> indent' (ppCode opts' (e ^. expectedFunctionTypeExpression))
                <> line
                <> "the expression"
              <+> ppCode opts' (e ^. expectedFunctionTypeApp)
              <+> "is expected to have a function type but has type:"
                <> line
                <> indent' (ppCode opts' (e ^. expectedFunctionTypeType))
          subjectExpr :: Expression
          subjectExpr = e ^. expectedFunctionTypeExpression

data WrongNumberArgumentsIndType = WrongNumberArgumentsIndType
  { _wrongNumberArgumentsIndTypeActualType :: Expression,
    _wrongNumberArgumentsIndTypeExpectedNumArgs :: Int,
    _wrongNumberArgumentsIndTypeActualNumArgs :: Int
  }

makeLenses ''WrongNumberArgumentsIndType

instance ToGenericError WrongNumberArgumentsIndType where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = i,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i]
            }
        where
          opts' = fromGenericOptions opts
          ty = e ^. wrongNumberArgumentsIndTypeActualType
          i = getLoc ty
          expectedNumArgs = e ^. wrongNumberArgumentsIndTypeExpectedNumArgs
          actualNumArgs = e ^. wrongNumberArgumentsIndTypeActualNumArgs
          msg =
            "The type"
              <+> ppCode opts' ty
              <+> "expects"
              <+> ( if
                        | expectedNumArgs == 0 -> "no arguments"
                        | expectedNumArgs == 1 -> "one argument"
                        | otherwise -> pretty expectedNumArgs <+> "arguments"
                  )
                <> ", but"
              <+> ( if
                        | actualNumArgs == 0 -> "no argument is"
                        | actualNumArgs == 1 -> "only one argument is"
                        | otherwise -> pretty actualNumArgs <+> "arguments are"
                  )
              <+> "given"

newtype ImpracticalPatternMatching = ImpracticalPatternMatching
  { _impracticalPatternMatchingType :: Expression
  }

makeLenses ''ImpracticalPatternMatching

instance ToGenericError ImpracticalPatternMatching where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = i,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i]
            }
        where
          opts' = fromGenericOptions opts
          ty = e ^. impracticalPatternMatchingType
          i = getLoc ty
          msg =
            "The type"
              <+> ppCode opts' ty
              <+> "is not an inductive data type."
              <+> "Therefore, pattern-matching is not available here"

data NoPositivity = NoPositivity
  { _noStrictPositivityType :: Name,
    _noStrictPositivityConstructor :: Name,
    _noStrictPositivityArgument :: Expression
  }

makeLenses ''NoPositivity

instance ToGenericError NoPositivity where
  genericError e = ask >>= generr
    where
      generr opts =
        return
          GenericError
            { _genericErrorLoc = j,
              _genericErrorMessage = ppOutput msg,
              _genericErrorIntervals = [i, j]
            }
        where
          opts' = fromGenericOptions opts
          ty = e ^. noStrictPositivityType
          ctor = e ^. noStrictPositivityConstructor
          arg = e ^. noStrictPositivityArgument
          i = getLoc ty
          j = getLoc arg
          msg =
            "The type"
              <+> ppCode opts' ty
              <+> "is not strictly positive."
                <> line
                <> "It appears at a negative position in one of the arguments of the constructor"
              <+> ppCode opts' ctor <> "."
