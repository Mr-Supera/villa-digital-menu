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
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      categories: {
        Row: {
          created_at: string
          icon: string | null
          id: string
          is_active: boolean
          name_en: string | null
          name_pt: string
          parent_id: string | null
          section: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          icon?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_pt: string
          parent_id?: string | null
          section: string
          sort_order?: number
        }
        Update: {
          created_at?: string
          icon?: string | null
          id?: string
          is_active?: boolean
          name_en?: string | null
          name_pt?: string
          parent_id?: string | null
          section?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      items: {
        Row: {
          category_id: string
          created_at: string
          description_en: string | null
          description_pt: string | null
          id: string
          image_url: string | null
          is_active: boolean
          is_available: boolean
          is_featured: boolean
          name_en: string | null
          name_pt: string
          price: number
          sort_order: number
          updated_at: string
        }
        Insert: {
          category_id: string
          created_at?: string
          description_en?: string | null
          description_pt?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_available?: boolean
          is_featured?: boolean
          name_en?: string | null
          name_pt: string
          price?: number
          sort_order?: number
          updated_at?: string
        }
        Update: {
          category_id?: string
          created_at?: string
          description_en?: string | null
          description_pt?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_available?: boolean
          is_featured?: boolean
          name_en?: string | null
          name_pt?: string
          price?: number
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          id: string
          item_id: string | null
          name_snapshot: string
          note: string | null
          order_id: string
          price_snapshot: number
          quantity: number
        }
        Insert: {
          id?: string
          item_id?: string | null
          name_snapshot: string
          note?: string | null
          order_id: string
          price_snapshot: number
          quantity: number
        }
        Update: {
          id?: string
          item_id?: string | null
          name_snapshot?: string
          note?: string | null
          order_id?: string
          price_snapshot?: number
          quantity?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          created_at: string
          customer_name: string | null
          customer_note: string | null
          id: string
          ip_hash: string | null
          order_number: number
          public_token: string
          seen_at: string | null
          session_id: string | null
          status: string
          table_id: string
          table_number: string
          total: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          customer_name?: string | null
          customer_note?: string | null
          id?: string
          ip_hash?: string | null
          order_number?: number
          public_token?: string
          seen_at?: string | null
          session_id?: string | null
          status?: string
          table_id: string
          table_number: string
          total?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          customer_name?: string | null
          customer_note?: string | null
          id?: string
          ip_hash?: string | null
          order_number?: number
          public_token?: string
          seen_at?: string | null
          session_id?: string | null
          status?: string
          table_id?: string
          table_number?: string
          total?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "table_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_table_id_fkey"
            columns: ["table_id"]
            isOneToOne: false
            referencedRelation: "restaurant_tables"
            referencedColumns: ["id"]
          },
        ]
      }
      pin_attempts: {
        Row: {
          attempted_at: string
          device_hash: string
          id: string
          table_id: string
        }
        Insert: {
          attempted_at?: string
          device_hash: string
          id?: string
          table_id: string
        }
        Update: {
          attempted_at?: string
          device_hash?: string
          id?: string
          table_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "pin_attempts_table_id_fkey"
            columns: ["table_id"]
            isOneToOne: false
            referencedRelation: "restaurant_tables"
            referencedColumns: ["id"]
          },
        ]
      }
      price_history: {
        Row: {
          changed_at: string
          changed_by: string | null
          changed_by_email: string | null
          id: string
          item_id: string | null
          item_name: string | null
          new_price: number | null
          old_price: number | null
        }
        Insert: {
          changed_at?: string
          changed_by?: string | null
          changed_by_email?: string | null
          id?: string
          item_id?: string | null
          item_name?: string | null
          new_price?: number | null
          old_price?: number | null
        }
        Update: {
          changed_at?: string
          changed_by?: string | null
          changed_by_email?: string | null
          id?: string
          item_id?: string | null
          item_name?: string | null
          new_price?: number | null
          old_price?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "price_history_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "items"
            referencedColumns: ["id"]
          },
        ]
      }
      restaurant_tables: {
        Row: {
          id: string
          is_active: boolean
          label: string | null
          number: string
          sort_order: number
        }
        Insert: {
          id?: string
          is_active?: boolean
          label?: string | null
          number: string
          sort_order?: number
        }
        Update: {
          id?: string
          is_active?: boolean
          label?: string | null
          number?: string
          sort_order?: number
        }
        Relationships: []
      }
      session_tokens: {
        Row: {
          created_at: string
          device_hash: string | null
          id: string
          session_id: string
          token_hash: string
        }
        Insert: {
          created_at?: string
          device_hash?: string | null
          id?: string
          session_id: string
          token_hash: string
        }
        Update: {
          created_at?: string
          device_hash?: string | null
          id?: string
          session_id?: string
          token_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "session_tokens_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "table_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      settings: {
        Row: {
          is_public: boolean
          key: string
          updated_at: string
          updated_by: string | null
          value: string | null
        }
        Insert: {
          is_public?: boolean
          key: string
          updated_at?: string
          updated_by?: string | null
          value?: string | null
        }
        Update: {
          is_public?: boolean
          key?: string
          updated_at?: string
          updated_by?: string | null
          value?: string | null
        }
        Relationships: []
      }
      table_keys: {
        Row: {
          access_key: string
          rotated_at: string
          table_id: string
        }
        Insert: {
          access_key?: string
          rotated_at?: string
          table_id: string
        }
        Update: {
          access_key?: string
          rotated_at?: string
          table_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_keys_table_id_fkey"
            columns: ["table_id"]
            isOneToOne: true
            referencedRelation: "restaurant_tables"
            referencedColumns: ["id"]
          },
        ]
      }
      table_session_secrets: {
        Row: {
          pin_hash: string
          session_id: string
        }
        Insert: {
          pin_hash: string
          session_id: string
        }
        Update: {
          pin_hash?: string
          session_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_session_secrets_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: true
            referencedRelation: "table_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      table_sessions: {
        Row: {
          closed_at: string | null
          closed_by: string | null
          failed_attempts: number
          id: string
          last_activity_at: string
          locked_until: string | null
          opened_at: string
          opened_device_hash: string | null
          status: string
          table_id: string
        }
        Insert: {
          closed_at?: string | null
          closed_by?: string | null
          failed_attempts?: number
          id?: string
          last_activity_at?: string
          locked_until?: string | null
          opened_at?: string
          opened_device_hash?: string | null
          status?: string
          table_id: string
        }
        Update: {
          closed_at?: string | null
          closed_by?: string | null
          failed_attempts?: number
          id?: string
          last_activity_at?: string
          locked_until?: string | null
          opened_at?: string
          opened_device_hash?: string | null
          status?: string
          table_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_sessions_table_id_fkey"
            columns: ["table_id"]
            isOneToOne: false
            referencedRelation: "restaurant_tables"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          email: string | null
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          email?: string | null
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          email?: string | null
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      _ts_device: { Args: { p_device_id: string }; Returns: string }
      _ts_hash: { Args: { p: string }; Returns: string }
      _ts_is_crew: { Args: never; Returns: boolean }
      _ts_new_token: {
        Args: { p_device_hash: string; p_session: string }
        Returns: string
      }
      _ts_norm: { Args: { p: string }; Returns: string }
      _ts_pin_weak: { Args: { p_pin: string }; Returns: boolean }
      _ts_session: { Args: { p_token: string }; Returns: string }
      _ts_setting: { Args: { p_key: string }; Returns: string }
      _ts_table: { Args: { p_key: string; p_table: string }; Returns: string }
      admin_exists: { Args: never; Returns: boolean }
      claim_first_admin: { Args: never; Returns: boolean }
      create_order: {
        Args: {
          p_customer_name: string
          p_customer_note: string
          p_device_id: string
          p_honeypot: string
          p_items: Json
          p_token: string
        }
        Returns: Json
      }
      end_table_by_client: { Args: { p_token: string }; Returns: Json }
      end_table_by_staff: { Args: { p_table_id: string }; Returns: Json }
      expire_sessions: { Args: never; Returns: Json }
      get_order_status: { Args: { p_token: string }; Returns: Json }
      get_ordering_status: { Args: never; Returns: Json }
      get_session_orders: { Args: { p_token: string }; Returns: Json }
      get_table_state: {
        Args: { p_key: string; p_table: string; p_token?: string }
        Returns: Json
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_staff: { Args: { _user_id: string }; Returns: boolean }
      join_table: {
        Args: {
          p_device_id: string
          p_key: string
          p_pin: string
          p_table: string
        }
        Returns: Json
      }
      list_tables_status: { Args: never; Returns: Json }
      open_table: {
        Args: {
          p_device_id: string
          p_key: string
          p_pin: string
          p_table: string
        }
        Returns: Json
      }
      open_table_by_staff: {
        Args: { p_pin: string; p_table_id: string }
        Returns: Json
      }
      rotate_all_table_keys: { Args: never; Returns: Json }
      rotate_table_key: { Args: { p_table_id: string }; Returns: Json }
      set_ordering_enabled: { Args: { p_enabled: boolean }; Returns: boolean }
    }
    Enums: {
      app_role: "admin" | "editor" | "staff"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "editor", "staff"],
    },
  },
} as const
