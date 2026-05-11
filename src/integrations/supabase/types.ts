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
    PostgrestVersion: "13.0.5"
  }
  public: {
    Tables: {
      articles: {
        Row: {
          author: string | null
          content: string | null
          created_at: string
          display_order: number | null
          id: string
          image_url: string | null
          link_text: string | null
          link_url: string | null
          published_at: string | null
          show_on_homepage: boolean | null
          summary: string | null
          title: string
          type: string | null
          updated_at: string
          video_url: string | null
        }
        Insert: {
          author?: string | null
          content?: string | null
          created_at?: string
          display_order?: number | null
          id?: string
          image_url?: string | null
          link_text?: string | null
          link_url?: string | null
          published_at?: string | null
          show_on_homepage?: boolean | null
          summary?: string | null
          title: string
          type?: string | null
          updated_at?: string
          video_url?: string | null
        }
        Update: {
          author?: string | null
          content?: string | null
          created_at?: string
          display_order?: number | null
          id?: string
          image_url?: string | null
          link_text?: string | null
          link_url?: string | null
          published_at?: string | null
          show_on_homepage?: boolean | null
          summary?: string | null
          title?: string
          type?: string | null
          updated_at?: string
          video_url?: string | null
        }
        Relationships: []
      }
      biography: {
        Row: {
          created_at: string
          id: string
          motivation_quote: string | null
          personal_bio: string
          personal_image_url: string | null
          portrait_image_url: string | null
          professional_bio: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          motivation_quote?: string | null
          personal_bio: string
          personal_image_url?: string | null
          portrait_image_url?: string | null
          professional_bio: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          motivation_quote?: string | null
          personal_bio?: string
          personal_image_url?: string | null
          portrait_image_url?: string | null
          professional_bio?: string
          updated_at?: string
        }
        Relationships: []
      }
      contact_info: {
        Row: {
          address: string | null
          contact_page_image_url: string | null
          email: string
          facebook_url: string | null
          id: string
          instagram_url: string | null
          linkedin_url: string | null
          phone: string | null
          portrait_1_name: string | null
          portrait_1_url: string | null
          portrait_2_name: string | null
          portrait_2_url: string | null
          portrait_3_name: string | null
          portrait_3_url: string | null
          portrait_4_name: string | null
          portrait_4_url: string | null
          portrait_5_name: string | null
          portrait_5_url: string | null
          portrait_6_name: string | null
          portrait_6_url: string | null
          twitter_url: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          contact_page_image_url?: string | null
          email: string
          facebook_url?: string | null
          id?: string
          instagram_url?: string | null
          linkedin_url?: string | null
          phone?: string | null
          portrait_1_name?: string | null
          portrait_1_url?: string | null
          portrait_2_name?: string | null
          portrait_2_url?: string | null
          portrait_3_name?: string | null
          portrait_3_url?: string | null
          portrait_4_name?: string | null
          portrait_4_url?: string | null
          portrait_5_name?: string | null
          portrait_5_url?: string | null
          portrait_6_name?: string | null
          portrait_6_url?: string | null
          twitter_url?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          contact_page_image_url?: string | null
          email?: string
          facebook_url?: string | null
          id?: string
          instagram_url?: string | null
          linkedin_url?: string | null
          phone?: string | null
          portrait_1_name?: string | null
          portrait_1_url?: string | null
          portrait_2_name?: string | null
          portrait_2_url?: string | null
          portrait_3_name?: string | null
          portrait_3_url?: string | null
          portrait_4_name?: string | null
          portrait_4_url?: string | null
          portrait_5_name?: string | null
          portrait_5_url?: string | null
          portrait_6_name?: string | null
          portrait_6_url?: string | null
          twitter_url?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      contact_messages: {
        Row: {
          created_at: string
          email: string
          id: string
          is_read: boolean | null
          message: string
          name: string
        }
        Insert: {
          created_at?: string
          email: string
          id?: string
          is_read?: boolean | null
          message: string
          name: string
        }
        Update: {
          created_at?: string
          email?: string
          id?: string
          is_read?: boolean | null
          message?: string
          name?: string
        }
        Relationships: []
      }
      conversations: {
        Row: {
          content: string | null
          created_at: string
          display_order: number | null
          id: string
          image_url: string | null
          is_published: boolean | null
          link_text: string
          link_url: string | null
          summary: string | null
          title: string
          updated_at: string
          videos: Json | null
        }
        Insert: {
          content?: string | null
          created_at?: string
          display_order?: number | null
          id?: string
          image_url?: string | null
          is_published?: boolean | null
          link_text: string
          link_url?: string | null
          summary?: string | null
          title: string
          updated_at?: string
          videos?: Json | null
        }
        Update: {
          content?: string | null
          created_at?: string
          display_order?: number | null
          id?: string
          image_url?: string | null
          is_published?: boolean | null
          link_text?: string
          link_url?: string | null
          summary?: string | null
          title?: string
          updated_at?: string
          videos?: Json | null
        }
        Relationships: []
      }
      core_messages: {
        Row: {
          created_at: string
          description: string
          icon: string | null
          id: string
          order_index: number | null
          title: string
          vision_theme_id: string | null
        }
        Insert: {
          created_at?: string
          description: string
          icon?: string | null
          id?: string
          order_index?: number | null
          title: string
          vision_theme_id?: string | null
        }
        Update: {
          created_at?: string
          description?: string
          icon?: string | null
          id?: string
          order_index?: number | null
          title?: string
          vision_theme_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "core_messages_vision_theme_id_fkey"
            columns: ["vision_theme_id"]
            isOneToOne: false
            referencedRelation: "vision_themes"
            referencedColumns: ["id"]
          },
        ]
      }
      event_registrations: {
        Row: {
          created_at: string
          email: string
          event_id: string
          id: string
          name: string
        }
        Insert: {
          created_at?: string
          email: string
          event_id: string
          id?: string
          name: string
        }
        Update: {
          created_at?: string
          email?: string
          event_id?: string
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "event_registrations_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
        ]
      }
      events: {
        Row: {
          created_at: string
          description: string | null
          event_date: string
          event_type: string | null
          id: string
          is_cancelled: boolean | null
          location: string
          location_address: string | null
          max_participants: number | null
          registration_link: string | null
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          event_date: string
          event_type?: string | null
          id?: string
          is_cancelled?: boolean | null
          location: string
          location_address?: string | null
          max_participants?: number | null
          registration_link?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          event_date?: string
          event_type?: string | null
          id?: string
          is_cancelled?: boolean | null
          location?: string
          location_address?: string | null
          max_participants?: number | null
          registration_link?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      hero_content: {
        Row: {
          about_section_content: string | null
          about_section_heading: string | null
          about_section_image_url: string | null
          created_at: string
          cta_text: string | null
          flyer_image_url: string | null
          flyer_url: string | null
          heading: string
          id: string
          subheading: string | null
          updated_at: string
          video_intro_heading: string | null
          video_intro_label: string | null
          video_intro_text: string | null
          video_url: string
        }
        Insert: {
          about_section_content?: string | null
          about_section_heading?: string | null
          about_section_image_url?: string | null
          created_at?: string
          cta_text?: string | null
          flyer_image_url?: string | null
          flyer_url?: string | null
          heading: string
          id?: string
          subheading?: string | null
          updated_at?: string
          video_intro_heading?: string | null
          video_intro_label?: string | null
          video_intro_text?: string | null
          video_url: string
        }
        Update: {
          about_section_content?: string | null
          about_section_heading?: string | null
          about_section_image_url?: string | null
          created_at?: string
          cta_text?: string | null
          flyer_image_url?: string | null
          flyer_url?: string | null
          heading?: string
          id?: string
          subheading?: string | null
          updated_at?: string
          video_intro_heading?: string | null
          video_intro_label?: string | null
          video_intro_text?: string | null
          video_url?: string
        }
        Relationships: []
      }
      hobbies: {
        Row: {
          created_at: string
          description: string | null
          icon_name: string | null
          id: string
          order_index: number | null
          title: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          icon_name?: string | null
          id?: string
          order_index?: number | null
          title: string
        }
        Update: {
          created_at?: string
          description?: string | null
          icon_name?: string | null
          id?: string
          order_index?: number | null
          title?: string
        }
        Relationships: []
      }
      newsletter_subscribers: {
        Row: {
          email: string
          id: string
          is_active: boolean | null
          name: string | null
          subscribed_at: string
        }
        Insert: {
          email: string
          id?: string
          is_active?: boolean | null
          name?: string | null
          subscribed_at?: string
        }
        Update: {
          email?: string
          id?: string
          is_active?: boolean | null
          name?: string | null
          subscribed_at?: string
        }
        Relationships: []
      }
      pages: {
        Row: {
          created_at: string
          id: string
          order_index: number | null
          slug: string
          title: string
        }
        Insert: {
          created_at?: string
          id?: string
          order_index?: number | null
          slug: string
          title: string
        }
        Update: {
          created_at?: string
          id?: string
          order_index?: number | null
          slug?: string
          title?: string
        }
        Relationships: []
      }
      portraits: {
        Row: {
          created_at: string
          description: string
          id: string
          image_url: string | null
          name: string
          order_index: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description: string
          id?: string
          image_url?: string | null
          name: string
          order_index?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string
          id?: string
          image_url?: string | null
          name?: string
          order_index?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          created_at: string
          full_name: string | null
          id: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          full_name?: string | null
          id?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          full_name?: string | null
          id?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      proposers_recommendations: {
        Row: {
          created_at: string
          document_1_title: string | null
          document_1_url: string | null
          document_2_title: string | null
          document_2_url: string | null
          document_box_title: string
          id: string
          text_box_content: string | null
          text_box_title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          document_1_title?: string | null
          document_1_url?: string | null
          document_2_title?: string | null
          document_2_url?: string | null
          document_box_title?: string
          id?: string
          text_box_content?: string | null
          text_box_title?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          document_1_title?: string | null
          document_1_url?: string | null
          document_2_title?: string | null
          document_2_url?: string | null
          document_box_title?: string
          id?: string
          text_box_content?: string | null
          text_box_title?: string
          updated_at?: string
        }
        Relationships: []
      }
      recommendations: {
        Row: {
          content: string
          created_at: string
          id: string
          order_index: number | null
          title: string
          updated_at: string
        }
        Insert: {
          content: string
          created_at?: string
          id?: string
          order_index?: number | null
          title: string
          updated_at?: string
        }
        Update: {
          content?: string
          created_at?: string
          id?: string
          order_index?: number | null
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      support_declarations: {
        Row: {
          created_at: string
          email: string
          id: string
          is_approved: boolean | null
          is_public: boolean | null
          location: string | null
          message: string | null
          name: string
          role: string | null
          wants_to_be_proposer: boolean | null
        }
        Insert: {
          created_at?: string
          email: string
          id?: string
          is_approved?: boolean | null
          is_public?: boolean | null
          location?: string | null
          message?: string | null
          name: string
          role?: string | null
          wants_to_be_proposer?: boolean | null
        }
        Update: {
          created_at?: string
          email?: string
          id?: string
          is_approved?: boolean | null
          is_public?: boolean | null
          location?: string | null
          message?: string | null
          name?: string
          role?: string | null
          wants_to_be_proposer?: boolean | null
        }
        Relationships: []
      }
      supporters: {
        Row: {
          created_at: string
          id: string
          image_url: string | null
          name: string
          order_index: number | null
          quote: string
          video_url: string | null
        }
        Insert: {
          created_at?: string
          id?: string
          image_url?: string | null
          name: string
          order_index?: number | null
          quote: string
          video_url?: string | null
        }
        Update: {
          created_at?: string
          id?: string
          image_url?: string | null
          name?: string
          order_index?: number | null
          quote?: string
          video_url?: string | null
        }
        Relationships: []
      }
      tasks: {
        Row: {
          category: string | null
          completed_at: string | null
          created_at: string
          description: string | null
          due_date: string | null
          id: string
          priority: Database["public"]["Enums"]["task_priority"]
          reminder_minutes: number | null
          source: string | null
          status: Database["public"]["Enums"]["task_status"]
          summary: string | null
          title: string
          transcript: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          category?: string | null
          completed_at?: string | null
          created_at?: string
          description?: string | null
          due_date?: string | null
          id?: string
          priority?: Database["public"]["Enums"]["task_priority"]
          reminder_minutes?: number | null
          source?: string | null
          status?: Database["public"]["Enums"]["task_status"]
          summary?: string | null
          title: string
          transcript?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          category?: string | null
          completed_at?: string | null
          created_at?: string
          description?: string | null
          due_date?: string | null
          id?: string
          priority?: Database["public"]["Enums"]["task_priority"]
          reminder_minutes?: number | null
          source?: string | null
          status?: Database["public"]["Enums"]["task_status"]
          summary?: string | null
          title?: string
          transcript?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      user_settings: {
        Row: {
          created_at: string
          id: string
          onboarding_completed: boolean
          theme: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          onboarding_completed?: boolean
          theme?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          onboarding_completed?: boolean
          theme?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      vision_page_content: {
        Row: {
          created_at: string
          id: string
          order_index: number
          section_content: string
          section_key: string
          section_title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          order_index?: number
          section_content: string
          section_key: string
          section_title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          order_index?: number
          section_content?: string
          section_key?: string
          section_title?: string
          updated_at?: string
        }
        Relationships: []
      }
      vision_themes: {
        Row: {
          article_id: string | null
          content: string
          created_at: string
          icon_name: string | null
          id: string
          image_url: string | null
          order_index: number | null
          subtitle: string | null
          title: string
          updated_at: string
          video_url: string | null
        }
        Insert: {
          article_id?: string | null
          content: string
          created_at?: string
          icon_name?: string | null
          id?: string
          image_url?: string | null
          order_index?: number | null
          subtitle?: string | null
          title: string
          updated_at?: string
          video_url?: string | null
        }
        Update: {
          article_id?: string | null
          content?: string
          created_at?: string
          icon_name?: string | null
          id?: string
          image_url?: string | null
          order_index?: number | null
          subtitle?: string | null
          title?: string
          updated_at?: string
          video_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "vision_themes_article_id_fkey"
            columns: ["article_id"]
            isOneToOne: false
            referencedRelation: "articles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_admin: { Args: { _user_id: string }; Returns: boolean }
    }
    Enums: {
      app_role: "admin" | "user"
      task_priority: "urgent" | "high" | "medium" | "low"
      task_status: "todo" | "in_progress" | "done"
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
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
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
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
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
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
      app_role: ["admin", "user"],
      task_priority: ["urgent", "high", "medium", "low"],
      task_status: ["todo", "in_progress", "done"],
    },
  },
} as const
