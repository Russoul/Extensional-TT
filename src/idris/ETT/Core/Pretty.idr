module ETT.Core.Pretty

import Data.Fin
import Data.String
import Data.Util

import Text.PrettyPrint.Prettyprinter.Render.Terminal
import Text.PrettyPrint.Prettyprinter

import ETT.Core.Language
import ETT.Core.Monad
import ETT.Core.Shrinking
import ETT.Core.Substitution
import ETT.Core.Evaluation

-- (x : A{≥0}) → A{≥0}
-- e{≥3} ≡ e{≥3} ∈ e{≥0}
-- El e{≥4}

-- x ↦ e{≥0}
-- S e{≥4}

public export
data Ann = Keyword | ContextVar | SignatureVar | Form | Elim | Intro

public export
parens' : Doc Ann -> Doc Ann
parens' = enclose (annotate Keyword lparen) (annotate Keyword rparen)

public export
brackets' : Doc Ann -> Doc Ann
brackets' = enclose (annotate Keyword lbracket) (annotate Keyword rbracket)

Level = Fin 5

wrapElem : Elem -> Level -> Doc Ann -> M (Doc Ann)
wrapElem (PiTy x dom cod) lvl doc =
  case !(shrink cod 1 0) of
    Nothing =>
      case lvl <= 0 of
        True => return doc
        False => return (parens' doc)
    Just _ =>
      case lvl <= 2 of
        True => return doc
        False => return (parens' doc)
wrapElem (PiVal {}) lvl doc =
  case lvl <= 0 of
    True => return doc
    False => return (parens' doc)
wrapElem (PiElim {}) lvl doc =
  case lvl <= 3 of
    True => return doc
    False => return (parens' doc)
wrapElem NatVal0 lvl doc =
  case lvl <= 4 of
    True => return doc
    False => return (parens' doc)
wrapElem Universe lvl doc =
  case lvl <= 4 of
    True => return doc
    False => return (parens' doc)
wrapElem (NatVal1 x) lvl doc =
  case lvl <= 3 of
    True => return doc
    False => return (parens' doc)
wrapElem NatTy lvl doc =
  case lvl <= 4 of
    True => return doc
    False => return (parens' doc)
wrapElem (NatElim str x y str1 str2 z w) lvl doc =
  case lvl <= 3 of
    True => return doc
    False => return (parens' doc)
wrapElem tm@(ContextSubstElim {}) lvl doc = assert_total $ idris_crash "wrapElem(ContextSubstElim)"
wrapElem tm@(SignatureSubstElim {}) lvl doc = assert_total $ idris_crash "wrapElem(SignatureSubstElim)"
wrapElem (ContextVarElim {}) lvl doc =
  case lvl <= 4 of
    True => return doc
    False => return (parens' doc)
wrapElem (SignatureVarElim {}) lvl doc =
  case lvl <= 3 of
    True => return doc
    False => return (parens' doc)
wrapElem (OmegaVarElim {}) lvl doc =
  case lvl <= 3 of
    True => return doc
    False => return (parens' doc)
wrapElem (EqTy {}) lvl doc =
  case lvl <= 1 of
    True => return doc
    False => return (parens' doc)
wrapElem (EqVal {}) lvl doc =
  case lvl <= 4 of
    True => return doc
    False => return (parens' doc)

||| Examples:
||| i .j. ⊦ j
||| i .j. k ⊦ j
||| i i .i. ⊦ i
||| i .i. i ⊦ i{1}
||| .i. i i ⊦ i{2}
||| .i. i a b c d i ⊦ i{2}
||| That is: we render the "root" of the name,
||| and its de-bruijn index w.r.t. all names in the *same context*
||| that have the *same root*.
public export
localise : SnocList VarName -> Nat -> M (VarName, Nat)
localise [<] idx = throw "Exception in 'localise'"
localise (xs :< x) Z = return (x, 0)
localise (xs :< x) (S k) = M.do
  (name, idx) <- localise xs k
  case name == x of
    True => return (name, S idx)
    False => return (name, idx)

public export
prettySignatureVar : Signature -> Nat -> M (Doc Ann)
prettySignatureVar sig i = M.do
  -- return (annotate SignatureVar (pretty $ "χ" ++ natToSuperscript i))
  (n, 0) <- localise (map fst sig) i
    | (n, k) =>
        return (annotate SignatureVar (pretty n <+> "{" <+> pretty k <+> "}"))
  return (annotate SignatureVar (pretty n))

public export
prettyContextVar : SnocList VarName -> Nat -> M (Doc Ann)
prettyContextVar sig i = M.do
  -- return (annotate SignatureVar (pretty $ "x" ++ natToSuperscript i))
  (n, 0) <- localise sig i
    | (n, k) =>
        return (annotate ContextVar (pretty n <+> "{" <+> pretty k <+> "}"))
  return (annotate ContextVar (pretty n))

mutual
  public export
  prettySubstContextNu' : Signature -> Omega -> SnocList VarName -> SubstContextNF -> M (Doc Ann)
  prettySubstContextNu' sig omega ctx (WkN k) = return (pretty "↑\{natToSuperscript k}")
  prettySubstContextNu' sig omega ctx (Ext sigma t) = return $ parens' $
    !(prettySubstContext' sig omega ctx sigma)
     <+>
    annotate Keyword ","
     <++>
    !(prettyElem sig omega ctx t 0)
  prettySubstContextNu' sig omega ctx Terminal = return "·"

  public export
  prettySubstContext' : Signature -> Omega -> SnocList VarName -> SubstContext -> M (Doc Ann)
  prettySubstContext' sig omega ctx sigma = prettySubstContextNu' sig omega ctx (eval sigma)

  public export
  prettySubstContext : Signature -> Omega -> SnocList VarName -> SubstContext -> M (Doc Ann)
  prettySubstContext sig omega ctx sigma = prettySubstContext' sig omega ctx sigma

  public export
  prettyElem' : Signature
             -> Omega
             -> SnocList VarName
             -> Elem
             -> M (Doc Ann)
  prettyElem' sig omega ctx (PiTy x dom cod) = M.do
    case !(shrink cod 1 0) of
      Nothing => M.do
        return $
          annotate Intro lparen
           <+>
          annotate ContextVar (pretty x)
           <++>
          annotate Keyword ":"
           <++>
          !(prettyElem sig omega ctx dom 0)
           <+>
          annotate Intro rparen
           <++>
          annotate Keyword "→"
           <++>
          !(prettyElem sig omega (ctx :< x) cod 0)
      Just cod => M.do
        return $
          !(prettyElem sig omega ctx dom 3)
           <++>
          annotate Keyword "→"
           <++>
          !(prettyElem sig omega ctx cod 2)
  prettyElem' sig omega ctx (PiVal x _ _ f) =
    return $
      annotate ContextVar (pretty x)
       <++>
      annotate Intro "↦"
       <++>
      !(prettyElem sig omega (ctx :< x) f 0)
  prettyElem' sig omega ctx (PiElim f x a b e) =
    return $
      !(prettyElem sig omega ctx f 3)
       <++>
      !(prettyElem sig omega ctx e 4)
  prettyElem' sig omega ctx NatVal0 =
    return $ annotate Intro "0"
  prettyElem' sig omega ctx Universe =
    return $ annotate Form "𝕌"
  prettyElem' sig omega ctx (NatVal1 e) = return $
    annotate Intro "S"
      <++>
    !(prettyElem sig omega ctx e 4)
  prettyElem' sig omega ctx NatTy =
    return $ annotate Intro "ℕ"
  prettyElem' sig omega ctx (NatElim x schema z y h s t) = M.do
    return $
      annotate Elim "ℕ-elim"
       <++>
      parens' (annotate ContextVar (pretty x) <+> annotate Keyword "." <++> !(prettyElem sig omega (ctx :< x) schema 0))
       <++>
      !(prettyElem sig omega ctx z 4)
       <++>
      parens' (annotate ContextVar (pretty y)
                <+>
               annotate Keyword "."
                <+>
               annotate ContextVar (pretty h)
                <+>
               annotate Keyword "."
                <++>
               !(prettyElem sig omega (ctx :< y :< h) s 0)
              )
       <++>
      !(prettyElem sig omega ctx t 4)
  prettyElem' sig omega ctx tm@(ContextSubstElim {}) = assert_total $ idris_crash "prettyElem'(ContextSubstElim)"
  prettyElem' sig omega ctx tm@(SignatureSubstElim {}) = assert_total $ idris_crash "prettyElem'(SignatureSubstElim)"
  prettyElem' sig omega ctx (ContextVarElim k) =
    prettyContextVar ctx k
  prettyElem' sig omega ctx (SignatureVarElim k sigma) = M.do
    x <- prettySignatureVar sig k
    return $
      x
       <+>
      parens' !(prettySubstContext sig omega ctx sigma)
  prettyElem' sig omega ctx (OmegaVarElim k sigma) = M.do
    let x = annotate Elim (pretty k)
    return $
      x
       <+>
      parens' !(prettySubstContext sig omega ctx sigma)
  prettyElem' sig omega ctx (EqTy l r ty) = return $
    !(prettyElem sig omega ctx l 3)
     <++>
    annotate Form "≡"
     <++>
    !(prettyElem sig omega ctx r 3)
     <++>
    annotate Form "∈"
     <++>
    !(prettyElem sig omega ctx ty 0)
  prettyElem' sig omega ctx EqVal =
    return $ annotate Intro "*"

  public export
  prettyElem : Signature
            -> Omega
            -> SnocList VarName
            -> Elem
            -> Level
            -> M (Doc Ann)
  prettyElem sig omega ctx tm lvl = M.do
    tm <- openEval sig omega tm
    wrapElem tm lvl !(prettyElem' sig omega ctx tm)

  public export
  tail : Context -> SnocList (VarName, Elem)
  tail Empty = [<]
  tail (SignatureVarElim {}) = [<]
  tail (Ext tyes x ty) = tail tyes :< (x, ty)

  head : Context -> Either () Nat
  head Empty = Left ()
  head (SignatureVarElim x) = Right x
  head (Ext tyes x ty) = head tyes

  public export
  prettyTelescope : Signature
                 -> Omega
                 -> SnocList VarName
                 -> List (VarName, Elem)
                 -> M (Doc Ann)
  prettyTelescope sig omega ctx [] = return ""
  prettyTelescope sig omega ctx ((x, ty) :: tyes) = return $
    lparen
     <+>
    annotate ContextVar (pretty x)
     <++>
    annotate Keyword ":"
     <++>
    !(prettyElem sig omega ctx ty 0)
     <+>
    rparen
     <++>
    !(prettyTelescope sig omega (ctx :< x) tyes)

  public export
  prettyContext : Signature
               -> Omega
               -> Context
               -> M (Doc Ann)
  prettyContext sig omega ctx =
    case head ctx of
      Left () => prettyTelescope sig omega [<] (cast $ tail ctx)
      Right x => return $
        !(prettySignatureVar sig x) <++> !(prettyTelescope sig omega [<] (cast $ tail ctx))

  public export
  prettySignatureEntry : Signature -> Omega -> VarName -> SignatureEntry -> M (Doc Ann)
   -- χ ctx
   -- Γ ⊦ χ type
   -- Γ ⊦ χ : A
   -- Γ ⊦ χ ≔ e : A
  prettySignatureEntry sig omega x CtxEntry = return (pretty x <++> annotate Keyword "ctx")
  prettySignatureEntry sig omega x (TypeEntry ctx) = return $
    !(prettyContext sig omega ctx)
     <++>
    annotate Keyword "⊦"
     <++>
    annotate ContextVar (pretty x)
     <++>
    annotate Keyword "type"
  prettySignatureEntry sig omega x (ElemEntry ctx ty) = return $
    !(prettyContext sig omega ctx)
     <++>
    annotate Keyword "⊦"
     <++>
    annotate ContextVar (pretty x)
     <++>
    annotate Keyword ":"
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) ty 0)
  prettySignatureEntry sig omega x (LetElemEntry ctx e ty) = return $
    !(prettyContext sig omega ctx)
     <++>
    annotate Keyword "⊦"
     <++>
    annotate ContextVar (pretty x)
     <++>
    annotate Keyword "≔"
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) e 0)
     <++>
    annotate Keyword ":"
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) ty 0)
  prettySignatureEntry sig omega x (EqTyEntry ctx a b) = return $
    !(prettyContext sig omega ctx)
     <++>
    annotate Keyword "⊦"
     <++>
    brackets' (annotate ContextVar (pretty x))
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) a 0)
     <++>
    annotate Keyword "="
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) b 0)
     <++>
    annotate Keyword "type"

  public export
  prettyConstraintEntry : Signature -> Omega -> ConstraintEntry -> M (Doc Ann)
  prettyConstraintEntry sig omega (TypeConstraint ctx a b) = M.do
   return $
    !(prettyContext sig omega ctx)
     <++>
    annotate Keyword "⊦"
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) a 0)
     <++>
    annotate Keyword "="
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) b 0)
     <++>
    annotate Keyword "type"
  prettyConstraintEntry sig omega (ElemConstraint ctx a b ty) = M.do
   return $
    !(prettyContext sig omega ctx)
     <++>
    annotate Keyword "⊦"
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) a 0)
     <++>
    annotate Keyword "="
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) b 0)
     <++>
    annotate Keyword ":"
     <++>
    !(prettyElem sig omega (map fst $ tail ctx) ty 0)
  prettyConstraintEntry sig omega (SubstContextConstraint sigma tau source target) = M.do
   return $
    !(prettySubstContext sig omega [<] sigma)
     <++>
    annotate Keyword "="
     <++>
    !(prettySubstContext sig omega [<] tau)
     <++>
    annotate Keyword ":"
     <++>
    !(prettyContext sig omega source)
     <++>
    annotate Keyword "⇒"
     <++>
    !(prettyContext sig omega target)


  public export
  prettySignature' : Signature -> Omega -> List (VarName, SignatureEntry) -> M (Doc Ann)
  prettySignature' sig omega [] = return ""
  prettySignature' sig omega ((x, e) :: es) = return $
    parens' !(prettySignatureEntry sig omega x e)
     <+>
    hardline
     <+>
    !(prettySignature' (sig :< (x, e)) omega es)

  public export
  prettySignature : Signature -> Omega -> Signature -> M (Doc Ann)
  prettySignature sig omega sig' = prettySignature' sig omega (toList sig')

public export
renderDocAnsi : Doc AnsiStyle
             -> String
renderDocAnsi doc = renderString $ layoutPretty defaultLayoutOptions doc

toAnsiStyle : Ann -> AnsiStyle
toAnsiStyle Keyword = color Yellow
toAnsiStyle ContextVar = color BrightBlack
toAnsiStyle SignatureVar = color BrightBlack
toAnsiStyle Form = color Cyan
toAnsiStyle Elim = color Red
toAnsiStyle Intro = color Green

public export
renderDocTerm : Doc Ann
             -> String
renderDocTerm doc = renderDocAnsi (reAnnotate toAnsiStyle doc)

public export
renderDocNoAnn : Doc ann
              -> String
renderDocNoAnn doc = renderDocAnsi (unAnnotate doc)
