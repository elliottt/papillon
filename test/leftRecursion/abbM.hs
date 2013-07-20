{-# LANGUAGE PackageImports #-}

import "monads-tf" Control.Monad.State
import "monads-tf" Control.Monad.Error

data AB = A | B deriving Show
data S = Rec S AB | Atom AB deriving Show
-- data S = Rec AB S | Atom AB deriving Show

data Fail = Fail deriving Show

instance Error Fail where

type Return a = Either Fail (Either Bool a, Derivs)

data Derivs = Derivs {
	drvS :: Return S,
	chars :: Return AB
 }

testPackrat :: S
testPackrat = case drvS $ parse [A, B, B] of
	Right (Right r, _) -> r
	_ -> error "bad"

parse :: [AB] -> Derivs
parse s = d
	where
	d = Derivs ds dab
	ds = runStateT sm $ d { drvS = Right (Left False, d) }
	dab = flip runStateT d $ case s of
		c : cs -> do
			put $ parse cs
			return $ Right c
		_ -> throwError Fail

sm :: StateT Derivs (Either Fail) (Either Bool S)
sm = foldl1 mplus [ do
	sm' <- StateT drvS
	ss <- case sm' of
		Right s -> return s
		Left False -> do
--			d <- get
			modify $ setDrvS $ Left Fail
			ms' <- sm
--			put d
			case ms' of
				Right s' -> return s'
				_ -> throwError Fail
		Left True -> throwError Fail
	mc <- StateT chars
	case mc of
		Right c -> return $ Right $ Rec ss c
		_ -> throwError Fail
			
 , do	mc <- StateT chars
	case mc of
		Right c -> return $ Right $ Atom c
		_ -> throwError Fail
 ]

setDrvS :: Return S -> Derivs -> Derivs
setDrvS s d = d { drvS = s }
