<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('restaurants', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('currency_code', 3)->default('INR');
            $table->decimal('tax_rate', 5, 4)->default(0);
            $table->decimal('service_charge_rate', 5, 4)->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('restaurant_id')->nullable()->after('id')->constrained()->nullOnDelete();
            $table->string('role', 32)->default('waiter')->after('password');
            $table->boolean('is_active')->default(true)->after('role');
        });

        Schema::create('restaurant_tables', function (Blueprint $table) {
            $table->id();
            $table->foreignId('restaurant_id')->constrained()->cascadeOnDelete();
            $table->string('label');
            $table->string('public_token', 64)->unique();
            $table->unsignedTinyInteger('capacity')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('menu_categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('restaurant_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('menu_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('restaurant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('menu_categories')->cascadeOnDelete();
            $table->string('name');
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2);
            $table->string('image_url')->nullable();
            $table->string('diet', 16)->default('unknown');
            $table->unsignedSmallInteger('prep_minutes')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_available')->default(true);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('dining_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('restaurant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('table_id')->constrained('restaurant_tables')->cascadeOnDelete();
            $table->string('status', 16)->default('open'); // open|closed
            $table->string('access_token', 80)->unique();
            $table->boolean('allows_new_orders')->default(true);
            $table->timestamp('started_at');
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();

            $table->index(['table_id', 'status']);
        });

        Schema::create('session_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dining_session_id')->constrained()->cascadeOnDelete();
            $table->string('client_session_id', 64);
            $table->timestamp('joined_at');
            $table->timestamps();

            $table->unique(['dining_session_id', 'client_session_id']);
        });

        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dining_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('restaurant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('table_id')->constrained('restaurant_tables')->cascadeOnDelete();
            $table->string('status', 32)->default('pending');
            $table->decimal('subtotal', 10, 2);
            $table->decimal('tax', 10, 2)->default(0);
            $table->decimal('service_charge', 10, 2)->default(0);
            $table->decimal('grand_total', 10, 2);
            $table->string('notes')->nullable();
            $table->string('idempotency_key', 80)->nullable();
            $table->timestamps();

            $table->unique(['dining_session_id', 'idempotency_key']);
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('menu_item_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name_snapshot');
            $table->decimal('unit_price_snapshot', 10, 2);
            $table->unsignedInteger('quantity');
            $table->decimal('line_total', 10, 2);
            $table->string('note')->nullable();
            $table->timestamps();
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dining_session_id')->constrained()->cascadeOnDelete();
            $table->string('status', 32)->default('unpaid'); // unpaid|payment_pending|paid
            $table->decimal('amount_due', 10, 2)->default(0);
            $table->decimal('amount_paid', 10, 2)->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->foreignId('marked_by_staff_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique('dining_session_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('session_participants');
        Schema::dropIfExists('dining_sessions');
        Schema::dropIfExists('menu_items');
        Schema::dropIfExists('menu_categories');
        Schema::dropIfExists('restaurant_tables');
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('restaurant_id');
            $table->dropColumn(['role', 'is_active']);
        });
        Schema::dropIfExists('restaurants');
    }
};
