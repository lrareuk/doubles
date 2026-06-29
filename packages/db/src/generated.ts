export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      agendas: {
        Row: {
          created_at: string
          double_id: string
          id: string
          intent_text: string
          status: Database["public"]["Enums"]["agenda_status"]
          target_episode: number
          world_id: string
        }
        Insert: {
          created_at?: string
          double_id: string
          id?: string
          intent_text: string
          status?: Database["public"]["Enums"]["agenda_status"]
          target_episode: number
          world_id: string
        }
        Update: {
          created_at?: string
          double_id?: string
          id?: string
          intent_text?: string
          status?: Database["public"]["Enums"]["agenda_status"]
          target_episode?: number
          world_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "agendas_double_id_fkey"
            columns: ["double_id"]
            isOneToOne: false
            referencedRelation: "doubles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "agendas_world_id_fkey"
            columns: ["world_id"]
            isOneToOne: false
            referencedRelation: "worlds"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_log: {
        Row: {
          action: string
          created_at: string
          id: string
          metadata: Json
          user_id: string | null
          world_id: string | null
        }
        Insert: {
          action: string
          created_at?: string
          id?: string
          metadata?: Json
          user_id?: string | null
          world_id?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          id?: string
          metadata?: Json
          user_id?: string | null
          world_id?: string | null
        }
        Relationships: []
      }
      beats: {
        Row: {
          content: string
          created_at: string
          episode_id: string
          id: string
          kind: Database["public"]["Enums"]["beat_kind"]
          moderation_status: Database["public"]["Enums"]["moderation_verdict"]
          participant_double_ids: string[]
          visibility: Database["public"]["Enums"]["beat_visibility"]
          world_id: string
        }
        Insert: {
          content: string
          created_at?: string
          episode_id: string
          id?: string
          kind: Database["public"]["Enums"]["beat_kind"]
          moderation_status?: Database["public"]["Enums"]["moderation_verdict"]
          participant_double_ids?: string[]
          visibility?: Database["public"]["Enums"]["beat_visibility"]
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["beats"]["Insert"]>
        Relationships: []
      }
      bets: {
        Row: {
          created_at: string
          id: string
          market_id: string
          option_key: string
          resolved_episode: number | null
          stake_clout: number
          status: Database["public"]["Enums"]["bet_status"]
          user_id: string
          world_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          market_id: string
          option_key: string
          resolved_episode?: number | null
          stake_clout: number
          status?: Database["public"]["Enums"]["bet_status"]
          user_id: string
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["bets"]["Insert"]>
        Relationships: []
      }
      clout_balances: {
        Row: { balance: number; user_id: string; world_id: string }
        Insert: { balance?: number; user_id: string; world_id: string }
        Update: { balance?: number; user_id?: string; world_id?: string }
        Relationships: []
      }
      doubles: {
        Row: {
          avatar_seed: string
          created_at: string
          display_name: string
          handle: string
          id: string
          moderation_status: Database["public"]["Enums"]["moderation_status"]
          owner_user_id: string
          persona_prompt: string
          traits: Json
          updated_at: string
        }
        Insert: {
          avatar_seed?: string
          created_at?: string
          display_name: string
          handle: string
          id?: string
          moderation_status?: Database["public"]["Enums"]["moderation_status"]
          owner_user_id: string
          persona_prompt: string
          traits?: Json
          updated_at?: string
        }
        Update: Partial<Database["public"]["Tables"]["doubles"]["Insert"]>
        Relationships: []
      }
      entitlements: {
        Row: {
          created_at: string
          expires_at: string | null
          id: string
          sku: Database["public"]["Enums"]["entitlement_sku"]
          source: Database["public"]["Enums"]["entitlement_source"]
          status: Database["public"]["Enums"]["entitlement_status"]
          user_id: string
        }
        Insert: {
          created_at?: string
          expires_at?: string | null
          id?: string
          sku: Database["public"]["Enums"]["entitlement_sku"]
          source: Database["public"]["Enums"]["entitlement_source"]
          status?: Database["public"]["Enums"]["entitlement_status"]
          user_id: string
        }
        Update: Partial<Database["public"]["Tables"]["entitlements"]["Insert"]>
        Relationships: []
      }
      episodes: {
        Row: {
          created_at: string
          generated_at: string | null
          headline: string | null
          id: string
          number: number
          published_at: string | null
          status: Database["public"]["Enums"]["episode_status"]
          token_usage: Json | null
          world_id: string
        }
        Insert: {
          created_at?: string
          generated_at?: string | null
          headline?: string | null
          id?: string
          number: number
          published_at?: string | null
          status?: Database["public"]["Enums"]["episode_status"]
          token_usage?: Json | null
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["episodes"]["Insert"]>
        Relationships: []
      }
      markets: {
        Row: {
          created_at: string
          episode_opened: number
          id: string
          multiplier: number
          options: Json
          question: string
          resolves_on_episode: number
          status: Database["public"]["Enums"]["market_status"]
          winning_option: string | null
          world_id: string
        }
        Insert: {
          created_at?: string
          episode_opened: number
          id?: string
          multiplier?: number
          options: Json
          question: string
          resolves_on_episode: number
          status?: Database["public"]["Enums"]["market_status"]
          winning_option?: string | null
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["markets"]["Insert"]>
        Relationships: []
      }
      moderation_events: {
        Row: {
          created_at: string
          id: string
          reason: string | null
          subject_id: string
          subject_type: Database["public"]["Enums"]["moderation_subject"]
          verdict: Database["public"]["Enums"]["moderation_verdict"]
        }
        Insert: {
          created_at?: string
          id?: string
          reason?: string | null
          subject_id: string
          subject_type: Database["public"]["Enums"]["moderation_subject"]
          verdict: Database["public"]["Enums"]["moderation_verdict"]
        }
        Update: Partial<Database["public"]["Tables"]["moderation_events"]["Insert"]>
        Relationships: []
      }
      power_moves: {
        Row: {
          applied_at: string | null
          apply_on_episode: number
          created_at: string
          id: string
          payload: Json
          status: Database["public"]["Enums"]["power_move_status"]
          target_double_id: string | null
          type: Database["public"]["Enums"]["power_move_type"]
          user_id: string
          world_id: string
        }
        Insert: {
          applied_at?: string | null
          apply_on_episode: number
          created_at?: string
          id?: string
          payload?: Json
          status?: Database["public"]["Enums"]["power_move_status"]
          target_double_id?: string | null
          type: Database["public"]["Enums"]["power_move_type"]
          user_id: string
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["power_moves"]["Insert"]>
        Relationships: []
      }
      recaps: {
        Row: {
          created_at: string
          episode_id: string
          gated_beat_ids: string[]
          highlights: Json
          id: string
          narrative: string
          user_id: string
        }
        Insert: {
          created_at?: string
          episode_id: string
          gated_beat_ids?: string[]
          highlights?: Json
          id?: string
          narrative: string
          user_id: string
        }
        Update: Partial<Database["public"]["Tables"]["recaps"]["Insert"]>
        Relationships: []
      }
      relationships: {
        Row: {
          affinity: number
          from_double_id: string
          id: string
          to_double_id: string
          type: Database["public"]["Enums"]["relationship_type"]
          updated_at: string
          world_id: string
        }
        Insert: {
          affinity?: number
          from_double_id: string
          id?: string
          to_double_id: string
          type?: Database["public"]["Enums"]["relationship_type"]
          updated_at?: string
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["relationships"]["Insert"]>
        Relationships: []
      }
      reveal_unlocks: {
        Row: {
          beat_id: string
          created_at: string
          id: string
          source: Database["public"]["Enums"]["reveal_source"]
          user_id: string
        }
        Insert: {
          beat_id: string
          created_at?: string
          id?: string
          source: Database["public"]["Enums"]["reveal_source"]
          user_id: string
        }
        Update: Partial<Database["public"]["Tables"]["reveal_unlocks"]["Insert"]>
        Relationships: []
      }
      season_scores: {
        Row: {
          double_id: string
          drama: number
          glowup: number
          id: string
          ships: number
          updated_at: string
          villain: number
          world_id: string
        }
        Insert: {
          double_id: string
          drama?: number
          glowup?: number
          id?: string
          ships?: number
          updated_at?: string
          villain?: number
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["season_scores"]["Insert"]>
        Relationships: []
      }
      users: {
        Row: {
          age_verified: boolean
          age_verified_at: string | null
          created_at: string
          id: string
          status: Database["public"]["Enums"]["user_status"]
        }
        Insert: {
          age_verified?: boolean
          age_verified_at?: string | null
          created_at?: string
          id: string
          status?: Database["public"]["Enums"]["user_status"]
        }
        Update: Partial<Database["public"]["Tables"]["users"]["Insert"]>
        Relationships: []
      }
      world_invites: {
        Row: {
          created_at: string
          created_by: string
          expires_at: string | null
          id: string
          token: string
          used_at: string | null
          world_id: string
        }
        Insert: {
          created_at?: string
          created_by: string
          expires_at?: string | null
          id?: string
          token: string
          used_at?: string | null
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["world_invites"]["Insert"]>
        Relationships: []
      }
      world_members: {
        Row: {
          double_id: string
          id: string
          joined_at: string
          role: Database["public"]["Enums"]["member_role"]
          status: Database["public"]["Enums"]["member_status"]
          world_id: string
        }
        Insert: {
          double_id: string
          id?: string
          joined_at?: string
          role?: Database["public"]["Enums"]["member_role"]
          status?: Database["public"]["Enums"]["member_status"]
          world_id: string
        }
        Update: Partial<Database["public"]["Tables"]["world_members"]["Insert"]>
        Relationships: []
      }
      worlds: {
        Row: {
          created_at: string
          created_by: string
          current_episode: number
          id: string
          name: string
          season_ends_at: string | null
          season_number: number
          season_status: Database["public"]["Enums"]["season_status"]
          vibe: Database["public"]["Enums"]["world_vibe"]
        }
        Insert: {
          created_at?: string
          created_by: string
          current_episode?: number
          id?: string
          name: string
          season_ends_at?: string | null
          season_number?: number
          season_status?: Database["public"]["Enums"]["season_status"]
          vibe?: Database["public"]["Enums"]["world_vibe"]
        }
        Update: Partial<Database["public"]["Tables"]["worlds"]["Insert"]>
        Relationships: []
      }
    }
    Views: { [_ in never]: never }
    Functions: { [_ in never]: never }
    Enums: {
      agenda_status: "pending" | "in_progress" | "succeeded" | "failed"
      beat_kind: "post" | "dm" | "scene" | "twist" | "ship"
      beat_visibility: "public" | "reveal_gated"
      bet_status: "open" | "won" | "lost" | "void"
      entitlement_sku:
        | "sub_monthly"
        | "season_pass"
        | "consumable_powerpack"
        | "consumable_cloutpack"
        | "consumable_chaositem"
        | "cosmetic_avatar"
        | "cosmetic_season_theme"
        | "cosmetic_recap_card"
      entitlement_source: "subscription" | "season_pass" | "consumable" | "grant"
      entitlement_status: "active" | "expired"
      episode_status: "planning" | "generating" | "moderating" | "published" | "failed"
      market_status: "open" | "resolved" | "void"
      member_role: "host" | "member"
      member_status: "active" | "left" | "removed"
      moderation_status: "pending" | "ok" | "blocked"
      moderation_subject: "persona" | "beat"
      moderation_verdict: "ok" | "blocked"
      power_move_status: "queued" | "applied" | "expired"
      power_move_type: "whisper" | "rumour" | "sabotage" | "force_encounter" | "spotlight"
      relationship_type: "neutral" | "friend" | "ally" | "crush" | "rival" | "ex"
      reveal_source: "subscription" | "consumable"
      season_status: "active" | "finale" | "ended"
      user_status: "active" | "removed"
      world_vibe: "messy" | "wholesome_chaos" | "villain_arc" | "nobodys_safe"
    }
    CompositeTypes: { [_ in never]: never }
  }
}
