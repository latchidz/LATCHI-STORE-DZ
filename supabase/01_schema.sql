-- =====================================================================
--  LATCHI STORE DZ — Supabase Schema v1.0
--  Algerian local e-commerce · Cash on Delivery
--  Run this whole file in: Supabase Dashboard → SQL Editor → New query
-- =====================================================================
--  ORDER OF EXECUTION IS IMPORTANT. Do not reorder sections.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0) EXTENSIONS
-- ---------------------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- 1) ENUMS
-- ---------------------------------------------------------------------
do $$ begin
  create type public.user_role as enum ('merchant', 'customer');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.order_status as enum (
    'new', 'confirmed', 'canceled', 'postponed', 'in_delivery', 'delivered'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.delivery_mode as enum ('home', 'stopdesk');
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------
-- 2) TABLES
-- ---------------------------------------------------------------------

-- 2.1 profiles -------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text,
  phone        text,
  email        text,
  role         public.user_role not null default 'customer',
  avatar_url   text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
comment on table public.profiles is 'One row per auth user. role decides which app shell they see.';

-- 2.2 stores ---------------------------------------------------------
create table if not exists public.stores (
  id             uuid primary key default uuid_generate_v4(),
  owner_id       uuid not null references public.profiles(id) on delete cascade,
  name           text not null,
  slug           text unique,
  description    text,
  logo_url       text,
  phone          text,
  whatsapp       text,
  email          text,
  wilaya_code    text,
  commune_name   text,
  address        text,
  currency       text not null default 'DZD',
  -- إعدادات: delivery fees per wilaya live in store_delivery_rates
  home_delivery  boolean not null default true,
  stopdesk       boolean not null default true,
  free_ship_over numeric(12,2),
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- 2.3 delivery rates (per wilaya, per store) -------------------------
create table if not exists public.store_delivery_rates (
  id            uuid primary key default uuid_generate_v4(),
  store_id      uuid not null references public.stores(id) on delete cascade,
  wilaya_code   text not null,
  wilaya_name   text not null,
  home_price    numeric(12,2) not null default 0,
  stopdesk_price numeric(12,2) not null default 0,
  is_active     boolean not null default true,
  unique (store_id, wilaya_code)
);

-- 2.4 categories -----------------------------------------------------
create table if not exists public.categories (
  id          uuid primary key default uuid_generate_v4(),
  store_id    uuid not null references public.stores(id) on delete cascade,
  name        text not null,
  slug        text,
  image_url   text,
  position    int not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 2.5 products -------------------------------------------------------
create table if not exists public.products (
  id             uuid primary key default uuid_generate_v4(),
  store_id       uuid not null references public.stores(id) on delete cascade,
  category_id    uuid references public.categories(id) on delete set null,
  title          text not null,
  description    text,
  price          numeric(12,2) not null check (price >= 0),
  compare_price  numeric(12,2) check (compare_price is null or compare_price >= 0),
  cost_price     numeric(12,2),
  stock          int not null default 0 check (stock >= 0),
  sku            text,
  images         text[] not null default '{}',
  -- variants: [{"name":"اللون","options":["أحمر","أزرق"]}, ...]
  variant_schema jsonb not null default '[]'::jsonb,
  badge          text,                 -- "جديد" / "تخفيض" ...
  is_active      boolean not null default true,
  is_featured    boolean not null default false,
  views          int not null default 0,
  sold_count     int not null default 0,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists idx_products_store    on public.products(store_id) where is_active;
create index if not exists idx_products_category on public.products(category_id);
create index if not exists idx_products_search   on public.products
  using gin (to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(description,'')));

-- 2.6 product_variants (combinations + stock) ------------------------
create table if not exists public.product_variants (
  id          uuid primary key default uuid_generate_v4(),
  product_id  uuid not null references public.products(id) on delete cascade,
  label       text not null,            -- "أحمر / L"
  options     jsonb not null default '{}'::jsonb,  -- {"اللون":"أحمر","المقاس":"L"}
  price       numeric(12,2),            -- null = use product price
  stock       int not null default 0 check (stock >= 0),
  image_url   text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);
create index if not exists idx_variants_product on public.product_variants(product_id);

-- 2.7 orders ---------------------------------------------------------
create sequence if not exists public.order_number_seq start 1001;

create table if not exists public.orders (
  id              uuid primary key default uuid_generate_v4(),
  order_number    bigint not null default nextval('public.order_number_seq'),
  store_id        uuid not null references public.stores(id) on delete cascade,
  customer_id     uuid references public.profiles(id) on delete set null,
  -- بيانات التسليم (COD)
  customer_name   text not null,
  phone           text not null,
  phone_alt       text,
  wilaya_code     text not null,
  wilaya_name     text not null,
  commune_name    text not null,
  address         text,
  delivery_mode   public.delivery_mode not null default 'home',
  notes           text,
  -- المبالغ
  subtotal        numeric(12,2) not null default 0,
  delivery_price  numeric(12,2) not null default 0,
  discount        numeric(12,2) not null default 0,
  total_price     numeric(12,2) not null default 0,
  -- الحالة
  status          public.order_status not null default 'new',
  status_note     text,
  confirmed_at    timestamptz,
  delivered_at    timestamptz,
  -- التوصيل
  courier         text,                 -- yalidine | zr_express | ...
  tracking_number text,
  label_printed_at timestamptz,
  -- تتبع
  source          text default 'app',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (store_id, order_number)
);

create index if not exists idx_orders_store_status on public.orders(store_id, status);
create index if not exists idx_orders_created      on public.orders(store_id, created_at desc);
create index if not exists idx_orders_phone        on public.orders(phone);

-- 2.8 order_items ----------------------------------------------------
create table if not exists public.order_items (
  id            uuid primary key default uuid_generate_v4(),
  order_id      uuid not null references public.orders(id) on delete cascade,
  product_id    uuid references public.products(id) on delete set null,
  variant_id    uuid references public.product_variants(id) on delete set null,
  title         text not null,          -- snapshot
  image_url     text,
  quantity      int not null default 1 check (quantity > 0),
  unit_price    numeric(12,2) not null,
  variant_info  text,
  line_total    numeric(12,2) generated always as (quantity * unit_price) stored
);
create index if not exists idx_items_order on public.order_items(order_id);

-- 2.9 abandoned_leads ------------------------------------------------
create table if not exists public.abandoned_leads (
  id             uuid primary key default uuid_generate_v4(),
  store_id       uuid not null references public.stores(id) on delete cascade,
  customer_name  text,
  phone          text not null,
  wilaya_code    text,
  wilaya_name    text,
  commune_name   text,
  address        text,
  delivery_mode  public.delivery_mode default 'home',
  cart_snapshot  jsonb not null default '[]'::jsonb,
  cart_total     numeric(12,2) not null default 0,
  step_reached   text default 'form',   -- cart | form | confirm
  recovered      boolean not null default false,
  recovered_order uuid references public.orders(id) on delete set null,
  notes          text,
  created_at     timestamptz not null default now()
);
create index if not exists idx_leads_store on public.abandoned_leads(store_id, created_at desc);

-- 2.10 saved_carts (customer side, optional) -------------------------
create table if not exists public.cart_items (
  id         uuid primary key default uuid_generate_v4(),
  device_id  text not null,
  product_id uuid not null references public.products(id) on delete cascade,
  variant_id uuid references public.product_variants(id) on delete cascade,
  quantity   int not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  unique (device_id, product_id, variant_id)
);

-- 2.11 notifications (merchant) --------------------------------------
create table if not exists public.notifications (
  id         uuid primary key default uuid_generate_v4(),
  store_id   uuid not null references public.stores(id) on delete cascade,
  title      text not null,
  body       text,
  kind       text default 'order',      -- order | lead | system
  ref_id     uuid,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 3) TRIGGERS
-- ---------------------------------------------------------------------

-- 3.1 updated_at helper
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

do $$ declare t text;
begin
  foreach t in array array['profiles','stores','products','orders'] loop
    execute format('drop trigger if exists trg_touch_%1$s on public.%1$s', t);
    execute format('create trigger trg_touch_%1$s before update on public.%1$s
                    for each row execute function public.touch_updated_at()', t);
  end loop;
end $$;

-- 3.2 auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, phone, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', new.phone),
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'customer')
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3.3 order total recompute (server-side, never trust the client)
create or replace function public.recalc_order_total()
returns trigger language plpgsql as $$
declare s numeric(12,2);
begin
  select coalesce(sum(quantity * unit_price), 0) into s
  from public.order_items where order_id = coalesce(new.order_id, old.order_id);
  update public.orders
     set subtotal = s,
         total_price = greatest(s - discount + delivery_price, 0)
   where id = coalesce(new.order_id, old.order_id);
  return null;
end $$;

drop trigger if exists trg_recalc_order on public.order_items;
create trigger trg_recalc_order
  after insert or update or delete on public.order_items
  for each row execute function public.recalc_order_total();

-- 3.4 decrement stock on confirm, restore on cancel
create or replace function public.apply_stock_on_status()
returns trigger language plpgsql as $$
begin
  if new.status = 'confirmed' and (old.status is distinct from 'confirmed') then
    update public.products p
       set stock = greatest(p.stock - oi.quantity, 0),
           sold_count = p.sold_count + oi.quantity
      from public.order_items oi
     where oi.order_id = new.id and p.id = oi.product_id;
  elsif old.status = 'confirmed' and new.status = 'canceled' then
    update public.products p
       set stock = p.stock + oi.quantity,
           sold_count = greatest(p.sold_count - oi.quantity, 0)
      from public.order_items oi
     where oi.order_id = new.id and p.id = oi.product_id;
  end if;
  if new.status = 'confirmed' and new.confirmed_at is null then
    new.confirmed_at = now();
  end if;
  if new.status = 'delivered' and new.delivered_at is null then
    new.delivered_at = now();
  end if;
  return new;
end $$;

drop trigger if exists trg_stock_status on public.orders;
create trigger trg_stock_status
  before update of status on public.orders
  for each row execute function public.apply_stock_on_status();

-- 3.5 notification on new order
create or replace function public.notify_new_order()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (store_id, title, body, kind, ref_id)
  values (new.store_id,
          'طلب جديد #' || new.order_number,
          new.customer_name || ' — ' || new.wilaya_name || ' — ' || new.total_price || ' دج',
          'order', new.id);
  return new;
end $$;

drop trigger if exists trg_notify_order on public.orders;
create trigger trg_notify_order
  after insert on public.orders
  for each row execute function public.notify_new_order();

-- ---------------------------------------------------------------------
-- 4) ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table public.profiles             enable row level security;
alter table public.stores               enable row level security;
alter table public.store_delivery_rates enable row level security;
alter table public.categories           enable row level security;
alter table public.products             enable row level security;
alter table public.product_variants     enable row level security;
alter table public.orders               enable row level security;
alter table public.order_items          enable row level security;
alter table public.abandoned_leads      enable row level security;
alter table public.cart_items           enable row level security;
alter table public.notifications        enable row level security;

-- 4.1 helper: is current user the owner of this store?
create or replace function public.owns_store(sid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.stores s
    where s.id = sid and s.owner_id = auth.uid()
  );
$$;

-- 4.2 helper: is current user a merchant at all?
create or replace function public.is_merchant()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles p
                 where p.id = auth.uid() and p.role = 'merchant');
$$;

-- ---- profiles ----
drop policy if exists "profiles: read own"      on public.profiles;
drop policy if exists "profiles: update own"    on public.profiles;
drop policy if exists "profiles: insert own"    on public.profiles;
create policy "profiles: read own"   on public.profiles for select using (id = auth.uid());
create policy "profiles: update own" on public.profiles for update using (id = auth.uid())
                                                    with check (id = auth.uid());
create policy "profiles: insert own" on public.profiles for insert with check (id = auth.uid());

-- ---- stores: public can read active stores (storefront) ----
drop policy if exists "stores: public read"    on public.stores;
drop policy if exists "stores: owner all"      on public.stores;
create policy "stores: public read" on public.stores for select using (is_active = true);
create policy "stores: owner all"   on public.stores for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- ---- categories / products / variants: public read if active ----
drop policy if exists "categories: public read" on public.categories;
drop policy if exists "categories: merchant all" on public.categories;
create policy "categories: public read" on public.categories for select using (is_active = true);
create policy "categories: merchant all" on public.categories for all
  using (public.owns_store(store_id)) with check (public.owns_store(store_id));

drop policy if exists "products: public read" on public.products;
drop policy if exists "products: merchant all" on public.products;
create policy "products: public read" on public.products for select using (is_active = true);
create policy "products: merchant all" on public.products for all
  using (public.owns_store(store_id)) with check (public.owns_store(store_id));

drop policy if exists "variants: public read" on public.product_variants;
drop policy if exists "variants: merchant all" on public.product_variants;
create policy "variants: public read" on public.product_variants for select using (is_active = true);
create policy "variants: merchant all" on public.product_variants for all
  using (exists (select 1 from public.products p
                 where p.id = product_id and public.owns_store(p.store_id)))
  with check (exists (select 1 from public.products p
                 where p.id = product_id and public.owns_store(p.store_id)));

-- ---- delivery rates ----
drop policy if exists "rates: public read" on public.store_delivery_rates;
drop policy if exists "rates: merchant all" on public.store_delivery_rates;
create policy "rates: public read" on public.store_delivery_rates for select using (is_active = true);
create policy "rates: merchant all" on public.store_delivery_rates for all
  using (public.owns_store(store_id)) with check (public.owns_store(store_id));

-- ---- orders ----
-- Guest checkout is allowed: anon CAN insert. Nobody anonymous can READ.
drop policy if exists "orders: guest insert"    on public.orders;
drop policy if exists "orders: merchant read"   on public.orders;
drop policy if exists "orders: merchant update" on public.orders;
drop policy if exists "orders: merchant delete" on public.orders;
drop policy if exists "orders: customer read"   on public.orders;

create policy "orders: guest insert" on public.orders for insert
  with check (true);
create policy "orders: merchant read" on public.orders for select
  using (public.owns_store(store_id));
create policy "orders: merchant update" on public.orders for update
  using (public.owns_store(store_id)) with check (public.owns_store(store_id));
create policy "orders: merchant delete" on public.orders for delete
  using (public.owns_store(store_id));
create policy "orders: customer read" on public.orders for select
  using (customer_id = auth.uid());

-- ---- order_items ----
drop policy if exists "items: guest insert"  on public.order_items;
drop policy if exists "items: read"          on public.order_items;
create policy "items: guest insert" on public.order_items for insert with check (true);
create policy "items: read" on public.order_items for select using (
  exists (select 1 from public.orders o
          where o.id = order_id
            and (public.owns_store(o.store_id) or o.customer_id = auth.uid()))
);

-- ---- abandoned leads: insert-only for anon, read for merchant ----
drop policy if exists "leads: guest insert" on public.abandoned_leads;
drop policy if exists "leads: merchant all" on public.abandoned_leads;
create policy "leads: guest insert" on public.abandoned_leads for insert with check (true);
create policy "leads: merchant all" on public.abandoned_leads for all
  using (public.owns_store(store_id)) with check (public.owns_store(store_id));

-- ---- cart_items: device-scoped via RLS check on device_id param ----
drop policy if exists "cart: anon rw" on public.cart_items;
create policy "cart: anon rw" on public.cart_items for all
  using (true) with check (true);
-- NOTE: cart_items is device-scoped in the app layer (device_id filter).
-- If you want stricter isolation, move carts to local storage instead.

-- ---- notifications ----
drop policy if exists "notif: merchant read"   on public.notifications;
drop policy if exists "notif: merchant update" on public.notifications;
create policy "notif: merchant read" on public.notifications for select
  using (public.owns_store(store_id));
create policy "notif: merchant update" on public.notifications for update
  using (public.owns_store(store_id)) with check (public.owns_store(store_id));

-- ---------------------------------------------------------------------
-- 5) RPC — SERVER-SIDE CHECKOUT (single transaction, stock-safe)
-- ---------------------------------------------------------------------
-- The app calls this instead of 3 separate inserts.
-- Returns the new order id + order_number.
create or replace function public.place_order(
  p_store_id       uuid,
  p_customer_name  text,
  p_phone          text,
  p_phone_alt      text,
  p_wilaya_code    text,
  p_wilaya_name    text,
  p_commune_name   text,
  p_address        text,
  p_delivery_mode  public.delivery_mode,
  p_notes          text,
  p_items          jsonb,       -- [{"product_id":"..","variant_id":"..","quantity":2}]
  p_customer_id    uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id   uuid;
  v_order_no   bigint;
  v_subtotal   numeric(12,2) := 0;
  v_delivery   numeric(12,2) := 0;
  v_total      numeric(12,2) := 0;
  v_item       jsonb;
  v_price      numeric(12,2);
  v_qty        int;
  v_prod       record;
  v_var        record;
  v_rate       record;
begin
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_CART';
  end if;

  -- delivery price from the store's rate table
  select * into v_rate from public.store_delivery_rates
   where store_id = p_store_id and wilaya_code = p_wilaya_code and is_active;

  if found then
    v_delivery := case when p_delivery_mode = 'home'
                       then v_rate.home_price else v_rate.stopdesk_price end;
  end if;

  insert into public.orders (
    store_id, customer_id, customer_name, phone, phone_alt,
    wilaya_code, wilaya_name, commune_name, address,
    delivery_mode, notes, delivery_price, status
  ) values (
    p_store_id, p_customer_id, p_customer_name, p_phone, p_phone_alt,
    p_wilaya_code, p_wilaya_name, p_commune_name, p_address,
    p_delivery_mode, p_notes, coalesce(v_delivery,0), 'new'
  )
  returning id, order_number into v_order_id, v_order_no;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := greatest((v_item->>'quantity')::int, 1);

    select p.id, p.title, p.price, p.stock,
           (p.images)[1] as img
      into v_prod
      from public.products p
     where p.id = (v_item->>'product_id')::uuid
       and p.store_id = p_store_id
       and p.is_active;

    if not found then raise exception 'PRODUCT_NOT_FOUND:%', v_item->>'product_id'; end if;
    if v_prod.stock < v_qty then
      raise exception 'OUT_OF_STOCK:%', v_prod.title;
    end if;

    v_price := v_prod.price;
    v_var := null;

    if (v_item->>'variant_id') is not null then
      select * into v_var from public.product_variants
       where id = (v_item->>'variant_id')::uuid and product_id = v_prod.id;
      if found then
        if v_var.price is not null then v_price := v_var.price; end if;
        if v_var.stock < v_qty then raise exception 'OUT_OF_STOCK:%', v_prod.title; end if;
      end if;
    end if;

    insert into public.order_items (
      order_id, product_id, variant_id, title, image_url,
      quantity, unit_price, variant_info
    ) values (
      v_order_id, v_prod.id,
      case when v_var.id is null then null else v_var.id end,
      v_prod.title, v_prod.img, v_qty, v_price,
      case when v_var.id is null then null else v_var.label end
    );

    v_subtotal := v_subtotal + (v_price * v_qty);
  end loop;

  v_total := v_subtotal + coalesce(v_delivery,0);

  update public.orders
     set subtotal = v_subtotal,
         delivery_price = coalesce(v_delivery,0),
         total_price = v_total
   where id = v_order_id;

  return jsonb_build_object(
    'order_id', v_order_id,
    'order_number', v_order_no,
    'subtotal', v_subtotal,
    'delivery', coalesce(v_delivery,0),
    'total', v_total
  );
end $$;

grant execute on function public.place_order to anon, authenticated;

-- ---------------------------------------------------------------------
-- 6) RPC — LIVE ORDER TRACKING (by phone, rate-limited by nature)
-- ---------------------------------------------------------------------
create or replace function public.track_order(p_order_number bigint, p_phone text)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare o record;
begin
  select id, order_number, status, total_price, customer_name,
         wilaya_name, commune_name, delivery_mode, created_at, updated_at
    into o
    from public.orders
   where order_number = p_order_number
     and right(regexp_replace(phone, '\D', '', 'g'), 9)
       = right(regexp_replace(p_phone, '\D', '', 'g'), 9)
   limit 1;

  if not found then return null; end if;

  return jsonb_build_object(
    'order_number', o.order_number,
    'status', o.status,
    'total', o.total_price,
    'customer_name', o.customer_name,
    'wilaya', o.wilaya_name,
    'commune', o.commune_name,
    'delivery_mode', o.delivery_mode,
    'created_at', o.created_at,
    'updated_at', o.updated_at
  );
end $$;

grant execute on function public.track_order to anon, authenticated;

-- ---------------------------------------------------------------------
-- 7) RPC — MERCHANT DASHBOARD STATS
-- ---------------------------------------------------------------------
create or replace function public.store_stats(p_store_id uuid, p_days int default 30)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_cut timestamptz := now() - (p_days || ' days')::interval;
  r jsonb;
begin
  if not public.owns_store(p_store_id) then
    raise exception 'NOT_OWNER';
  end if;

  select jsonb_build_object(
    'orders_total',      count(*),
    'orders_new',        count(*) filter (where status = 'new'),
    'orders_confirmed',  count(*) filter (where status = 'confirmed'),
    'orders_delivered',  count(*) filter (where status = 'delivered'),
    'orders_canceled',   count(*) filter (where status = 'canceled'),
    'revenue_delivered', coalesce(sum(total_price) filter (where status = 'delivered'), 0),
    'revenue_pending',   coalesce(sum(total_price) filter (where status in ('new','confirmed','in_delivery')), 0),
    'avg_basket',        coalesce(round(avg(total_price), 2), 0)
  ) into r
  from public.orders
  where store_id = p_store_id and created_at >= v_cut;

  return r;
end $$;

grant execute on function public.store_stats to authenticated;

-- ---------------------------------------------------------------------
-- 8) STORAGE BUCKETS
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('product-images', 'product-images', true, 5242880,
   array['image/jpeg','image/png','image/webp']),
  ('store-assets',   'store-assets',   true, 2097152,
   array['image/jpeg','image/png','image/webp']),
  ('avatars',        'avatars',        true, 1048576,
   array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Public read for those buckets
drop policy if exists "storage: public read images" on storage.objects;
create policy "storage: public read images" on storage.objects for select
  using (bucket_id in ('product-images','store-assets','avatars'));

-- Only authenticated merchants may upload, into a folder named after their uid
drop policy if exists "storage: merchant upload" on storage.objects;
create policy "storage: merchant upload" on storage.objects for insert to authenticated
  with check (
    bucket_id in ('product-images','store-assets','avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "storage: merchant update" on storage.objects;
create policy "storage: merchant update" on storage.objects for update to authenticated
  using (
    bucket_id in ('product-images','store-assets','avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "storage: merchant delete" on storage.objects;
create policy "storage: merchant delete" on storage.objects for delete to authenticated
  using (
    bucket_id in ('product-images','store-assets','avatars')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------
-- 9) REALTIME
-- ---------------------------------------------------------------------
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.orders';        exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.abandoned_leads'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.notifications';   exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table public.products';        exception when others then null; end;
end $$;

-- ---------------------------------------------------------------------
-- 10) PROMOTE A USER TO MERCHANT (run manually after signing up)
-- ---------------------------------------------------------------------
-- update public.profiles set role = 'merchant' where email = 'owner@example.com';
-- insert into public.stores (owner_id, name, slug, phone)
--   select id, 'متجري', 'my-store', '0555000000' from public.profiles
--   where email = 'owner@example.com';

-- =====================================================================
--  END OF SCHEMA
-- =====================================================================
