module ExtTT.Core.Substitution

import Data.List

import Control.Monad.FailSt

import ExtTT.Core.Language

public export
M : Type -> Type
M = FailStM String ()

mutual
  namespace A
    ||| τ : Σ₀ ⇒ Σ₁
    ||| Σ₁ ⊦ σ : Γ ⇒ Δ
    ||| -----------------------
    ||| Σ₀ ⊦ σ(τ) : Γ(τ) ⇒ Δ(τ)
    ||| Σ₀ ⊦ (id Γ)(τ) = id Γ(τ) : Γ(τ) ⇒ Γ(τ)
    ||| Σ₀ ⊦ (↑ Γ A)(τ) = ↑ Γ(τ) A(τ) : Γ(τ) A(τ) ⇒ Γ(τ)
    ||| Σ₀ ⊦ (σ₁ ∘ σ₀)(τ) = σ₁(τ) ∘ σ(τ) : Γ₀(τ) ⇒ Γ₂(τ)
    ||| Σ₀ ⊦ (ext σ A t)(τ) = ext σ(τ) A(τ) t(τ) : Γ(τ) ⇒ Δ(τ) A(τ)
    ||| Σ₀ ⊦ (terminal Γ)(τ) = terminal Γ(τ) : Γ(τ) ⇒ ε
    ||| Σ₀ ⊦ σ(τ₀)(τ₁) = σ(τ₀ ∘ τ₁) : ...
    -- Σ₁ Δ ⊦ A type
    -- Σ₁ Γ ⊦ t : A(σ)
    -- Σ₀ Γ(τ) ⊦ t(τ) : A(τ)(σ(τ))   [= A(σ)(τ)]
    public export
    subst : SubstContext -> SubstSignature -> SubstContext
    -- (id Γ)(σ) = id Γ(σ)
    subst (Id ctx) sigma = Id (subst ctx sigma)
    -- (↑ Γ A)(σ) = ↑ Γ(σ) A(σ)
    subst (Wk ctx ty) sigma = Wk (subst ctx sigma) (subst ty sigma)
    subst (Chain tau0 tau1) sigma = Chain (SignatureSubstElim tau0 sigma) (SignatureSubstElim tau1 sigma)
    -- (τ, t : A)(σ) = τ(σ), t(σ) : A(σ)
    subst (Ext tau ty t) sigma = Ext (SignatureSubstElim tau sigma) (SignatureSubstElim ty sigma) (SignatureSubstElim t sigma)
    subst (Terminal dom) sigma = Terminal (subst dom sigma)
    subst (SignatureSubstElim tau sigma0) sigma1 = subst tau (Chain sigma0 sigma1)

    public export
    runSubst : SubstContext -> SubstContext
    runSubst (SignatureSubstElim sigma tau) = subst sigma tau
    runSubst x = x

    ||| i ∈ Σ₂
    ||| Σ₂ ⊦ σ : Δ ⇒ Γ
    ||| Σ₂ Γ ⊦ χᵢ : A
    ||| Σ₂ Δ ⊦ χᵢ σ : A(σ)
    ||| τ₀ : Σ₁ ⇒ Σ₂
    ||| τ₁ : Σ₀ ⇒ Σ₁
    ||| --------------------------------------------
    ||| Σ₀ Δ(τ₀)(τ₁) ⊦ (χᵢ σ)(τ₀)(τ₁) : A(σ)(τ₀)(τ₁)
    ||| Σ₀ Δ(↑)(τ : Σ₀ ⇒ Σ E) ⊦ (χᵢ σ)(↑)(τ) = (χᵢ₊₁ σ(↑))(τ)(id) : A(σ)(↑)(τ)       //↑ : Σ E ⇒ Σ
    -- Σ E ⊦ σ(↑) : Δ(↑) ⇒ Γ(↑)
    -- Σ Γ ⊦ χᵢ : A
    -- Σ E Γ(↑) ⊦ χᵢ₊₁ : A(↑)
    -- Σ E Δ(↑) ⊦ χᵢ₊₁ σ(↑) : A(σ)(↑)
    -- Σ₀ Δ(↑)(τ) ⊦ (χᵢ₊₁ σ(↑))(τ) : A(σ)(↑)(τ)
    ||| Σ₀ Δ(τ₀, t)(τ₁) ⊦ (χ₀ σ)(τ₀, t)(τ₁) = t(σ(τ₀, t))(τ₁) : A(↑)(σ)(τ₀, t)(τ₁)   [= A(τ₀)(σ(τ₀, t))(τ₁)]
    -- Σ₂ (Ω ⊦ A) Ω(↑) ⊦ χ₀ : A(↑)
    -- Σ₂ (Ω ⊦ A) ⊦ σ : Δ ⇒ Ω(↑)

    -- τ₀ : Σ₁ ⇒ Σ₂
    -- Σ₁ Ω(τ₀) ⊦ t : A(τ₀)
    -- τ₀, t : Σ₁ ⇒ Σ₂ (Ω ⊦ A)

    -- Σ₁ ⊦ σ(τ₀, t) : Δ(τ₀, t) ⇒ Ω(τ₀)
    -- Σ₂ ⊦ (Ω ⊦ A) entry
    -- Σ₁ Δ(τ₀, t) ⊦ t(σ(τ₀, t)) : A(τ₀)(σ(τ₀, t))
    -- Σ₀ Δ(τ₀, t)(τ₁) ⊦ t(σ(τ₀, t))(τ₁) : A(τ₀)(σ(τ₀, t))(τ₁)
    ||| Σ₀ Δ(τ₀)(τ₁) ⊦ (χ₁₊ᵢ σ)(τ₀, t)(τ₁) = (χᵢ σ)(τ₀)(τ₁) : A(↑Σ₂₁)(σ)(τ₀)(τ₁)

    -- Σ₂₀ (Γ ⊦ A) Σ₂₁ (Ω ⊦ C) Γ(↑)(↑Σ₂₁) ⊦ χ₁₊ᵢ : A(↑)(↑Σ₂₁)
    -- Σ₂₀ (Γ ⊦ A) Σ₂₁ Γ(↑Σ₂₁) ⊦ χᵢ : A(↑Σ₂₁)
    -- τ₀ : Σ₁ ⇒ Σ₂₀ (Γ ⊦ A) Σ₂₁
    -- Σ₁ Γ(↑Σ₂₁)(τ₀) ⊦ χᵢ(τ₁) : A(↑Σ₂₁)(τ₀)
    -- Σ₁ Δ(τ₀, t) ⊦ χᵢ(τ₁)(σ) = (χᵢ σ)(τ₁) : A(↑Σ₂₁)(τ₀)(σ)
    -- Σ₂₀ (Γ ⊦ A) Σ₂₁ (Ω ⊦ C) ⊦ σ : Δ ⇒ Γ(↑)(↑Σ₂₁)
    -- Σ₁ ⊦ σ : Δ(τ₀, t) ⇒ Γ(↑Σ₂₁)(τ₀)
    public export
    substSignatureVar : Nat -> SubstContext -> SubstSignature -> SubstSignature -> Elem
    substSignatureVar x spine Id Id = SignatureVarElim x spine
    substSignatureVar x spine Id sigma1 = substSignatureVar x spine sigma1 Id
    substSignatureVar x spine Wk sigma1 = substSignatureVar (S x) (SignatureSubstElim spine Wk) sigma1 Id
    substSignatureVar x spine (Chain Id tau) sigma = substSignatureVar x spine tau sigma
    substSignatureVar x spine (Chain tau0 tau1) sigma1 = substSignatureVar x spine tau0 (Chain tau1 sigma1)
    -- Σ (Δ ⊦ χ : A) | Γ ⊦ χ₀(ē)[τ, t] = t(ē[τ, t])
    -- Σ (Δ ⊦ χ : A) | Γ ⊦ χ₁₊ᵢ(ē)[τ, t] = χᵢ(ē[τ, t])[τ]
    substSignatureVar 0 spine (ExtElem tau t) sigma1 = FailSt.do
      subst (ContextSubstElim t (SignatureSubstElim spine (ExtElem tau t))) sigma1
    substSignatureVar (S k) spine (ExtElem tau t) sigma1 =
      substSignatureVar k spine tau sigma1
    substSignatureVar 0 spine (ExtTypE tau ty) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtTypE)"
    substSignatureVar (S k) spine (ExtTypE tau ty) sigma1 =
      substSignatureVar k spine tau sigma1
    substSignatureVar 0 spine (ExtCtx tau ty) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtCtx)"
    substSignatureVar (S k) spine (ExtCtx tau gamma) sigma1 =
      substSignatureVar k spine tau sigma1
    substSignatureVar 0 spine (ExtEqTy {}) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtEqTy)"
    substSignatureVar (S k) spine (ExtEqTy tau) sigma1 =
      substSignatureVar k spine tau sigma1
    substSignatureVar x spine Terminal sigma1 = assert_total $ idris_crash "substSignatureVar(Terminal)"

    ||| xᵢ(σ : Γ₁ ⇒ Γ₂)(τ : Γ₀ ⇒ Γ₁)
    substContextVarNu : Nat -> SubstContext -> SubstContext -> Elem
    substContextVarNu x (Id _) (Id _) = ContextVarElim x
    -- xᵢ(id : Γ ⇒ Γ)(τ : Γ₀ ⇒ Γ)
    substContextVarNu x (Id _) tau = substContextVar x tau (Id (dom tau))
    -- xᵢ(↑ : Γ (x : A) ⇒ Γ)(τ : Γ₀ ⇒ Γ (x : A))
    substContextVarNu x (Wk _ _) tau = substContextVar (S x) tau (Id (dom tau))
    substContextVarNu x (Chain (Id _) sigma) tau = substContextVar x sigma tau
    substContextVarNu x (Chain sigma0 sigma1) tau = substContextVar x sigma0 (Chain sigma1 tau)
    substContextVarNu 0 (Ext sigma ty t) tau = subst t tau
    substContextVarNu (S k) (Ext sigma ty t) tau = substContextVar k sigma tau
    substContextVarNu x (Terminal ctx) tau = assert_total $ idris_crash "substContextVarNu(Terminal)"
    substContextVarNu x (SignatureSubstElim {}) tau = assert_total $ idris_crash "substContextVarNu(SignatureSubstElim)"

    ||| xᵢ(σ)(τ)
    public export
    substContextVar : Nat -> SubstContext -> SubstContext -> Elem
    substContextVar x sigma tau = substContextVarNu x (runSubst sigma) tau

    namespace TypE
      ||| χᵢ(ē)[σ][τ]
      public export
      substSignatureVar : Nat -> SubstContext -> SubstSignature -> SubstSignature -> TypE
      substSignatureVar x spine Id Id = SignatureVarElim x spine
      substSignatureVar x spine Id sigma1 = substSignatureVar x spine sigma1 Id
      substSignatureVar x spine Wk sigma1 = substSignatureVar (S x) (SignatureSubstElim spine Wk) sigma1 Id
      substSignatureVar x spine (Chain Id tau) sigma = substSignatureVar x spine tau sigma
      substSignatureVar x spine (Chain tau0 tau1) sigma1 = substSignatureVar x spine tau0 (Chain tau1 sigma1)
      -- Σ (Δ ⊦ χ : A) | Γ ⊦ χ₀(ē)[τ, t] = t(ē[τ, t])
      -- Σ (Δ ⊦ χ : A) | Γ ⊦ χ₁₊ᵢ(ē)[τ, t] = χᵢ(ē[τ, t])[τ]
      substSignatureVar 0 spine (ExtTypE tau t) sigma1 = FailSt.do
        F.subst (ContextSubstElim t (SignatureSubstElim spine (ExtTypE tau t))) sigma1
      substSignatureVar (S k) spine (ExtTypE tau t) sigma1 =
        substSignatureVar k spine tau sigma1
      substSignatureVar 0 spine (ExtElem tau t) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtElem)"
      substSignatureVar (S k) spine (ExtElem tau t) sigma1 =
        substSignatureVar k spine tau sigma1
      substSignatureVar 0 spine (ExtCtx tau t) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtCtx)"
      substSignatureVar (S k) spine (ExtCtx tau t) sigma1 =
        substSignatureVar k spine tau sigma1
      substSignatureVar 0 spine (ExtEqTy tau) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtEqTy)"
      substSignatureVar (S k) spine (ExtEqTy tau) sigma1 =
        substSignatureVar k spine tau sigma1
      substSignatureVar x spine Terminal sigma1 = assert_total $ idris_crash "substSignatureVar(Terminal)"

  namespace B
    ||| t(σ)
    public export
    subst : Elem -> SubstContext -> Elem
    -- ℕ(σ) = ℕ
    subst NatTy sigma = NatTy
    -- (π A B)(σ) = π A(σ) B(σ⁺(El A))
    subst (PiTy x a b) sigma =
      PiTy x (ContextSubstElim a sigma) (ContextSubstElim b (Under sigma (El a)))
    -- (λ A B f)(σ) = λ A B(σ⁺(A)) f(σ⁺(A))
    subst (PiVal x a b f) sigma =
      PiVal x (ContextSubstElim a sigma) (ContextSubstElim b (Under sigma a)) (ContextSubstElim f (Under sigma a))
    -- (ap f A B e)(σ) = ap f(σ) A(σ) B(σ⁺(A)) e(σ)
    subst (PiElim f x a b e) sigma =
      PiElim (ContextSubstElim f sigma)
             x
             (ContextSubstElim a sigma)
             (ContextSubstElim b (Under sigma a))
             (ContextSubstElim e sigma)
    -- 0(σ) = 0
    subst NatVal0 sigma =
      NatVal0
    -- (S t)(σ) = S t(σ)
    subst (NatVal1 t) sigma =
      NatVal1 (ContextSubstElim t sigma)
    -- (ℕ-elim A z s t)(σ) = ℕ-elim A(σ⁺(ℕ)) z(σ) s(σ⁺(ℕ A ε)) t(σ)
    subst (NatElim x schema z y h s t) sigma =
      NatElim x
              (ContextSubstElim schema (Under sigma NatTy))
              z
              y
              h
              (ContextSubstElim s (UnderN [(y, NatTy), (h, schema)] sigma))
              t
    -- t(σ₀)(σ₁) = t(σ₀ ∘ σ₁)
    subst (ContextSubstElim t tau) sigma =
      subst t (Chain tau sigma)
    -- t(σ)(τ) = t(τ)(σ)
    subst (SignatureSubstElim t tau) sigma =
      subst (subst t tau) sigma
    -- χᵢ(σ) = χᵢ(σ)(id(dom σ))
    subst (ContextVarElim k) sigma = substContextVar k sigma (Id (dom sigma))
    -- Σ Δ ⊦ χ type
    -- Σ ⊦ σ : Γ ⇒ Δ
    -- Σ Γ ⊦ χ(σ)
    -- Σ₀ Γ(τ) ⊦ χ(σ)(τ) = χ(σ ∘ τ)
    subst (SignatureVarElim k sigma) tau = SignatureVarElim k (Chain sigma tau)
    subst (EqTy a0 a1 ty) tau = EqTy (ContextSubstElim a0 tau) (ContextSubstElim a1 tau) (ContextSubstElim ty tau)
    subst (EqVal a ty) tau = EqVal (ContextSubstElim a tau) (ContextSubstElim ty tau)
    -- Δ ⊦ A type
    -- Δ ⊦ a₀ : A
    -- σ : Γ ⇒ Δ
    -- (J A a₀ B r a₁ a)(σ) = J A(σ) a₀(σ) B(σ⁺(A (x₀ ≡ a₀(↑ Δ A) ∈ A(↑)) ε)) r(σ) a₁(σ) a(σ)
    subst (EqElim ty a0 x p schema r a1 a) tau =
        EqElim (ContextSubstElim ty tau)
               (ContextSubstElim a0 tau)
               x
               p
               -- τ : Δ ⇒ Γ
               -- Γ ⊦ a₀ : A
               -- Γ ⊦ (x : A) (p : x ≡ a₀(↑ Γ A) ∈ A(↑ Γ A))
               (ContextSubstElim schema
                 (UnderN [(x, ty),
                          (p, EqTy (ContextVarElim 0) (ContextSubstElim a0 (Wk (cod tau) ty)) (ContextSubstElim ty (Wk (cod tau) ty)))] tau
                 )
               )
               (ContextSubstElim r tau)
               (ContextSubstElim a1 tau)
               (ContextSubstElim a tau)

  namespace E
    ||| t(σ)
    public export
    subst : TypE -> SubstContext -> TypE
    -- (Π A B)(σ) = Π A(σ) B(σ⁺(A))
    subst (PiTy x a b) sigma =
      PiTy x (ContextSubstElim a sigma) (ContextSubstElim b (Under sigma a))
    -- t(σ)(τ) = t(σ ∘ τ)
    subst (ContextSubstElim t tau) sigma =
      subst t (Chain tau sigma)
    subst (SignatureSubstElim t tau) sigma =
      subst (subst t tau) sigma
    subst (EqTy a0 a1 ty) tau = EqTy (ContextSubstElim a0 tau) (ContextSubstElim a1 tau) (ContextSubstElim ty tau)
    subst NatTy tau = NatTy
    subst UniverseTy tau = UniverseTy
    -- χ(ē)(τ) = χ(σ(τ))
    subst (SignatureVarElim i sigma) tau =
      SignatureVarElim i (Chain sigma tau)
    subst (El u) tau = El (ContextSubstElim u tau)

  namespace C
    public export
    subst : Elem -> SubstSignature -> Elem
    subst (PiTy x a b) sigma = PiTy x (SignatureSubstElim a sigma) (SignatureSubstElim b sigma)
    subst (PiVal x a b f) sigma = PiVal x (SignatureSubstElim a sigma) (SignatureSubstElim b sigma) (SignatureSubstElim f sigma)
    subst (PiElim f x a b e) sigma =
      PiElim
          (SignatureSubstElim f sigma)
          x
          (SignatureSubstElim a sigma)
          (SignatureSubstElim b sigma)
          (SignatureSubstElim e sigma)
    subst NatVal0 sigma = NatVal0
    subst NatTy sigma = NatTy
    subst (NatVal1 t) sigma = NatVal1 (SignatureSubstElim t sigma)
    subst (NatElim x schema z y h s t) sigma =
      NatElim
         x
         (SignatureSubstElim schema sigma)
         (SignatureSubstElim z sigma)
         y
         h
         (SignatureSubstElim s sigma)
         (SignatureSubstElim t sigma)
    subst (ContextSubstElim t sigma) tau =
      subst (subst t sigma) tau
    subst (SignatureSubstElim t sigma0) sigma1 =
      subst t (Chain sigma0 sigma1)
    subst (ContextVarElim k) sigma = ContextVarElim k
    subst (SignatureVarElim k tau) sigma = substSignatureVar k tau sigma Id
    subst (EqTy a0 a1 ty) tau = EqTy (SignatureSubstElim a0 tau) (SignatureSubstElim a1 tau) (SignatureSubstElim ty tau)
    subst (EqVal a ty) tau = EqVal (SignatureSubstElim a tau) (SignatureSubstElim ty tau)
    subst (EqElim ty a0 x p schema r a1 a) tau =
        EqElim (SignatureSubstElim ty tau)
               (SignatureSubstElim a0 tau)
               x
               p
               (SignatureSubstElim schema tau)
               (SignatureSubstElim r tau)
               (SignatureSubstElim a1 tau)
               (SignatureSubstElim a tau)

  namespace F
    public export
    subst : TypE -> SubstSignature -> TypE
    subst (PiTy x a b) sigma = PiTy x (SignatureSubstElim a sigma) (SignatureSubstElim b sigma)
    subst (ContextSubstElim t sigma) tau =
      subst (subst t sigma) tau
    subst (SignatureSubstElim t sigma0) sigma1 =
      subst t (Chain sigma0 sigma1)
    subst (EqTy a0 a1 ty) tau = EqTy (SignatureSubstElim a0 tau) (SignatureSubstElim a1 tau) (SignatureSubstElim ty tau)
    subst NatTy tau = NatTy
    subst UniverseTy tau = UniverseTy
    -- χ(ē)[τ]
    subst (SignatureVarElim i sigma) tau = substSignatureVar i sigma tau Id
    subst (El u) tau = El (SignatureSubstElim u tau)

  namespace List
    public export
    subst : List -> SubstContext -> List
    subst [] sigma = []
    subst (t :: ts) sigma = ContextSubstElim t sigma :: subst ts sigma

  namespace ContextSpine
    public export
    subst : Spine -> SubstContext -> Spine
    subst [<] sigma = [<]
    subst (ts :< t) sigma = subst ts sigma :< ContextSubstElim t sigma

  namespace SignatureSpine
    public export
    subst : Spine -> SubstSignature -> Spine
    subst [<] sigma = [<]
    subst (ts :< t) sigma = subst ts sigma :< SignatureSubstElim t sigma

  namespace SignatureContext
    ||| τ : Σ₀ ⇛ Σ₁
    ||| Σ₁ ⊦ χ type
    ||| ------------
    ||| Σ₀ ⊦ χ(τ) type
    ||| Σ₀ ⊦ χ(τ) type
    public export
    substSignatureVar : Nat -> SubstSignature -> SubstSignature -> Context
    substSignatureVar x Id Id = SignatureVarElim x
    substSignatureVar x Id sigma1 = substSignatureVar x sigma1 Id
    substSignatureVar x Wk sigma1 = substSignatureVar (S x) sigma1 Id
    substSignatureVar x (Chain Id tau) sigma = substSignatureVar x tau sigma
    substSignatureVar x (Chain tau0 tau1) sigma1 = substSignatureVar x tau0 (Chain tau1 sigma1)
    --- τ : Σ₀ ⇛ Σ₁
    --- Σ₀ ⊦ Γ ctx
    --- ? ≔ (τ, Γ) : Σ₀ ⇛ Σ₁ (χ ctx)
    --- -------------------
    --- Σ₀ ⊦ χ₀(τ, Γ) = Γ ctx
    substSignatureVar 0 (ExtCtx tau ctx) sigma1 = FailSt.do
      subst ctx sigma1
    substSignatureVar (S k) (ExtCtx tau _) sigma1 =
      substSignatureVar k tau sigma1
    substSignatureVar 0 (ExtElem tau t) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtElem)"
    substSignatureVar (S k) (ExtElem tau t) sigma1 = substSignatureVar k tau sigma1
    substSignatureVar 0 (ExtTypE tau t) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtTypE)"
    substSignatureVar (S k) (ExtTypE tau t) sigma1 = substSignatureVar k tau sigma1
    substSignatureVar 0 (ExtEqTy tau) sigma1 = assert_total $ idris_crash "substSignatureVar(ExtEqTy)"
    substSignatureVar (S k) (ExtEqTy tau) sigma1 = substSignatureVar k tau sigma1
    substSignatureVar x Terminal sigma1 = assert_total $ idris_crash "substSignatureVar(Terminal)"

    public export
    dom : SubstContext -> Context
    dom (Id ctx) = ctx
    dom (Wk ctx ty) = Ext ctx "_" ty
    dom (Chain alpha beta) = dom beta
    dom (Ext sigma _ _) = dom sigma
    dom (Terminal ctx) = ctx
    dom (SignatureSubstElim sigma tau) = subst (dom sigma) tau

    public export
    cod : SubstContext -> Context
    cod (Id ctx) = ctx
    cod (Wk ctx ty) = ctx
    cod (Chain alpha beta) = cod alpha
    cod (Ext ctx ty t) = Ext (cod ctx) "_" ty
    cod (Terminal ctx) = Empty
    cod (SignatureSubstElim sigma tau) = subst (cod sigma) tau

    ||| σ : Γ₀ ⇒ Γ₁
    ||| Γ₁ ⊦ A type
    |||               ↑    σ
    ||| Γ₀ (x : A(σ)) ⇒ Γ₀ ⇒ Γ₁
    ||| σ⁺(A) = ext (σ ∘ ↑(Γ₀, A(σ)), A, x) : Γ₀ (x : A(σ)) ⇒ Γ₁ (x : A)
    public export
    Under : SubstContext -> TypE -> SubstContext
    Under sigma ty = Ext (Chain sigma (Wk (dom sigma) (ContextSubstElim ty sigma))) ty (ContextVarElim 0)

    ||| σ : Γ₀ ⇒ Γ₁
    ||| Γ₁ ⊦ Δ tel
    ||| σ⁺(Δ) : Γ₀ Δ(σ) ⇒ Γ₁ Δ
    ||| σ⁺(ε) = σ
    ||| σ⁺((x : A) Δ) = (σ⁺(A))⁺(Δ) : Γ₀ (x : A(σ)) Δ(σ⁺(A)) ⇒ Γ₁ (x : A) Δ
    public export
    UnderN : List (VarName, TypE) -> SubstContext -> SubstContext
    UnderN [] sigma = sigma
    UnderN ((x, ty) :: tyes) sigma = UnderN tyes (Under sigma ty)

    namespace Signature
      ||| σ : Σ₀ ⇒ Σ₁
      ||| Σ₁ ⊦ E sig-entry
      ||| -------------------
      ||| σ⁺(E) : Σ₀ E(σ) ⇒ Σ₁ E
      ||| σ⁺(Γ ⊦ A type) = σ ∘ ↑ : Σ₀ (Γ(σ) ⊦ A type) ⇒ Σ₁ (Γ ⊦ A type)
      -- Σ₀ (Γ(σ) ⊦ A type) Γ(σ)(↑) ⊦ χ₀ (id Γ(σ)(↑)) type
      ||| σ⁺(Γ ⊦ x : A) : Σ₀ (Γ(σ) ⊦ x : A(σ)) ⇒ Σ₁ (Γ ⊦ x : A)
      ||| σ⁺(Γ ⊦ x ≔ e : A) : Σ₀ (Γ(σ) ⊦ x ≔ e(σ) : A(σ)) ⇒ Σ₁ (Γ ⊦ x ≔ e : A)
      ||| σ⁺(Γ ⊦ A = B type) : Σ₀ (Γ(σ) ⊦ A(σ) = B(σ) type) ⇒ Σ₁ (Γ ⊦ A = B type)
      public export
      Under : SubstSignature -> SignatureEntry -> SubstSignature
      Under sigma CtxEntry = ExtCtx (Chain sigma Wk) Var
      Under sigma (TypEEntry ctx) = ExtTypE (Chain sigma Wk) (SignatureVarElim 0 (Id (subst ctx (Chain sigma Wk))))
      Under sigma (ElemEntry ctx ty) =
        ExtElem (Chain sigma Wk) (SignatureVarElim 0 (Id (subst ctx (Chain sigma Wk))))
      Under sigma (LetElemEntry ctx e ty) =
        ExtElem (Chain sigma Wk) (SignatureVarElim 0 (Id (subst ctx (Chain sigma Wk))))
      Under sigma (EqTyEntry ctx a b) =
        ExtEqTy (Chain sigma Wk)

      ||| σ : Σ₀ ⇒ Σ₁
      ||| Σ₁ ⊦ Δ sig
      ||| -------------------
      ||| σ⁺(Δ) : Σ₀ Δ(σ) ⇒ Σ₁ Δ
      ||| σ⁺(ε) : Σ₀ ⇒ Σ₁
      ||| σ⁺((x : E) Δ) : Σ₀ ((x : E(σ)) Δ(σ⁺(E))) ⇒ Σ₁ (x : E) Δ
      public export
      UnderN : SubstSignature -> List (VarName, SignatureEntry) -> SubstSignature
      UnderN sigma [] = sigma
      UnderN sigma ((x, e) :: es) = UnderN (Under sigma e) es


    public export
    subst : Context -> SubstSignature -> Context
    -- ε(τ) = ε
    subst Empty tau = Empty
    -- (Γ (x : A))(τ) = Γ(τ) (x : A(τ))
    subst (Ext ctx x ty) tau = Ext (subst ctx tau) x (SignatureSubstElim ty tau)
    -- χ(τ)
    subst (SignatureVarElim x) tau = substSignatureVar x tau Id

namespace SignatureEntry
  public export
  subst : SignatureEntry -> SubstSignature -> SignatureEntry
  subst CtxEntry sigma = CtxEntry
  subst (TypEEntry ctx) sigma = TypEEntry (subst ctx sigma)
  subst (ElemEntry ctx ty) sigma = ElemEntry (subst ctx sigma) (SignatureSubstElim ty sigma)
  subst (LetElemEntry ctx e ty) sigma = LetElemEntry (subst ctx sigma) (SignatureSubstElim e sigma) (SignatureSubstElim ty sigma)
  subst (EqTyEntry ctx a b) sigma = EqTyEntry (subst ctx sigma) (SignatureSubstElim a sigma) (SignatureSubstElim b sigma)

namespace EntryList
  public export
  subst : List (VarName, SignatureEntry) -> SubstSignature -> List (VarName, SignatureEntry)
  subst [] sigma = []
  subst ((x, e) :: es) sigma = (x, subst e sigma) :: subst es (Under sigma e)

namespace Signature
  public export
  subst : Signature -> SubstSignature -> Signature
  subst sig sigma = fromList (subst (toList sig) sigma)

namespace TypE
  public export
  runSubst : TypE -> TypE
  runSubst (ContextSubstElim t sigma) = subst t sigma
  runSubst (SignatureSubstElim t sigma) = subst t sigma
  runSubst t = t

namespace Elem
  public export
  runSubst : Elem -> Elem
  runSubst (ContextSubstElim t sigma) = subst t sigma
  runSubst (SignatureSubstElim t sigma) = subst t sigma
  runSubst t = t

public export
toContext : SnocList (VarName, TypE) -> Context
toContext [<] = Empty
toContext (tyes :< (x, ty)) = Ext (toContext tyes) x ty

||| Γ ⊦ id : Γ
||| ε ⊦ id = · : ε
||| Γ (x : A) ⊦ id = Γ (x : A) : ε
||| n = |Γ|
idSpine : SnocList (VarName, TypE) -> Spine
idSpine [<] = [<]
idSpine (tyes :< (x, ty)) =
  subst (idSpine tyes) (Wk (toContext tyes) ty) :< ContextVarElim 0
 -- Γ ⊦ id(Γ) : Γ
 -- Γ A ⊦ id(Γ A) = id(Γ)(↑), 0 : Γ A

mutual
  ||| σ : Γ ⇒ Δ
  ||| n = |Δ|
  ||| ------------------
  ||| Γ ⊦ toSpine(σ) : Δ
  public export
  toSpineNu : SnocList (VarName, TypE) -> SubstContext -> Spine
  toSpineNu delta (Id _) = idSpine delta
  -- ↑ : Γ (x : A) ⇒ Γ
  -- Γ (x : A) ⊦ toSpine(↑) : Γ
  toSpineNu delta (Wk delta0 ty) = ContextSpine.subst (idSpine delta) (Wk delta0 ty)
  -- σ : Γ ⇒ Δ
  -- τ : Δ ⇒ Ξ
  -- Γ ⊦ toSpine(τ)[σ] : Ξ
  -- τ : Δ ⇒ Ξ
  -- Γ ⊦ toSpine(σ ∘ τ) = toSpine(τ)[σ] : Ξ
  toSpineNu delta (Chain sigma tau) = subst (toSpine delta tau) sigma
  toSpineNu (delta :< (x, ty)) (Ext tau _ t) = toSpine delta tau :< t
  toSpineNu [<] (Ext {}) = assert_total $ idris_crash "toSpineNu(0, Ext)"
  toSpineNu [<] (Terminal _) = [<]
  toSpineNu (_ :< _) (Terminal _) = assert_total $ idris_crash "toSpineNu (S _, Terminal)"
  toSpineNu delta (SignatureSubstElim x y) = assert_total $ idris_crash "toSpineNu(SignatureSubstElim)"

  public export
  toSpine : SnocList (VarName, TypE) -> SubstContext -> Spine
  toSpine delta sigma = toSpineNu delta (runSubst sigma)

public export
quote : SubstContextNF -> SubstContext
quote (Terminal x) = Terminal x
quote (WkN x xs) = WkN x xs
quote (Ext sigma ty a) = Ext sigma ty a

public export
eval : SubstContext -> SubstContextNF
eval (Id ctx) = WkN ctx []
eval (Wk ctx a) = WkN ctx [("_", a)]
eval (Chain sigma tau) =
  case (eval sigma, eval tau) of
    (Terminal _, b) => Terminal (dom tau)
    (WkN x [], b) => b
    (WkN x (_ :: _), Terminal y) => assert_total $ idris_crash "eval" -- impossible by typing
    -- ↑ᵐ : Γ₀ Δ₀ ⇒ Γ₀
    -- Γ₀ = Γ₁ Δ₁
    -- ↑ⁿ : Γ₁ Δ₁ ⇒ Γ₁
    -- hence
    -- Γ₁ Δ₁ Δ₀
    (WkN x delta1@(_ :: _), WkN ctx delta0) => WkN ctx (delta1 ++ delta0)
    -- ↑ᵐ : Γ Δ (x : A) ⇒ Γ
    -- σ : Ω ⇒ Γ Δ (x : A)
    (WkN x list@(_ :: _), Ext sigma ty t) => eval (Chain (WkN x (init list)) sigma)
      -- ⟦↑ ∘ (σ, t)⟧ = ⟦id ∘ σ⟧ = ⟦σ⟧
    (Ext sigma ty t, _) => Ext (Chain sigma tau) (ContextSubstElim ty tau) (ContextSubstElim t tau)
eval (Ext sigma ty t) = Ext sigma ty t
eval (Terminal x) = Terminal x
eval tm@(SignatureSubstElim x y) = eval (runSubst tm)

public export
headNormalise : SubstContext -> SubstContext
headNormalise = quote . eval
