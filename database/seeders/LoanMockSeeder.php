<?php

namespace Database\Seeders;

use App\Models\Opportunity;
use Illuminate\Database\Seeder;

/**
 * Class LoanMockSeeder
 *
 * MOCKUP loan dataset for the deployment demo (CR-02) — NOT reviewed data.
 *
 * The product names are real Széchenyi Kártya Program MAX+ products, but every figure in `loan_terms` is an
 * illustrative sample, not the current terms: nobody has checked them against the official KAVOSZ Business Rules
 * (Üzletszabályzat). Each record says so in its terms, its source reference and its reviewer field.
 *
 * Before real use, replace each record with terms transcribed from the Business Rules and import it with
 * `php artisan fundor:import-reviewed-loan <file> --reviewed-by="<name>" --confirm-manual-review`.
 *
 * Deployment-only (origin): not meant for upstream.
 */
class LoanMockSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Shared by every mock record. The dates are the day this mockup was written — NOT a verification date.
        $mock = [
            'instrument_type' => 'subsidised_loan',
            'program' => 'Széchenyi Kártya Program MAX+',
            'status' => 'open',
            'effective_from_date' => '2026-09-29',
            'last_verified_date' => '2026-09-29',
            // Far enough ahead to keep the mockup visible; /api/loans hides records past their deadline.
            'deadline' => '2027-12-31',
            'source_document_reference' => 'MINTA – KAVOSZ Széchenyi Kártya Program MAX+ Üzletszabályzat (nem ellenőrzött)',
            'source_reference' => 'MINTA – KAVOSZ Széchenyi Kártya Program MAX+ Üzletszabályzat (nem ellenőrzött)',
            'manual_reviewed_by' => 'MINTA – nincs emberi ellenőrzés (mockup, not reviewed)',
            'curated' => true,
            // Loans never use the grant fields: the principal is not a funding award.
            'funding_min' => 0,
            'funding_max' => 0,
            'intensity' => 0,
        ];

        // Printed at the top and bottom of every terms text, in both languages (the field is not translated).
        $warning = "MINTA – szemléltető adatok, nem a hatályos feltételek.\nSAMPLE – illustrative figures, not the current terms.";
        $binding = 'A hatályos feltételeket a KAVOSZ Üzletszabályzata tartalmazza. / The binding terms are in the KAVOSZ Business Rules.';

        $loans = [
            [
                'code' => 'mock-szkp-folyoszamlahitel-max-plus',
                'title' => 'Széchenyi Kártya Folyószámlahitel MAX+',
                'loan_terms' => implode("\n", [
                    $warning,
                    'Hitelcél: a napi működés finanszírozása (folyószámlahitel). / Purpose: day-to-day operations (overdraft).',
                    'Hitelösszeg (minta): 1–250 millió Ft. / Amount (sample): HUF 1–250 million.',
                    'Futamidő (minta): 1–3 év. / Term (sample): 1–3 years.',
                    'Kamat (minta): évi 5%, fix. / Interest (sample): 5% a year, fixed.',
                    $binding,
                ]),
            ],
            [
                'code' => 'mock-szkp-beruhazasi-hitel-max-plus',
                'title' => 'Széchenyi Beruházási Hitel MAX+',
                'loan_terms' => implode("\n", [
                    $warning,
                    'Hitelcél: tárgyi eszköz beszerzése, beruházás. / Purpose: fixed assets and investment.',
                    'Hitelösszeg (minta): 1–500 millió Ft. / Amount (sample): HUF 1–500 million.',
                    'Futamidő (minta): legfeljebb 10 év. / Term (sample): up to 10 years.',
                    'Türelmi idő (minta): legfeljebb 2 év. / Grace period (sample): up to 2 years.',
                    'Kamat (minta): évi 5%, fix. / Interest (sample): 5% a year, fixed.',
                    'Saját forrás (minta): 10%. / Own contribution (sample): 10%.',
                    $binding,
                ]),
            ],
            [
                'code' => 'mock-szkp-forgoeszkozhitel-max-plus',
                'title' => 'Széchenyi Forgóeszközhitel MAX+',
                'loan_terms' => implode("\n", [
                    $warning,
                    'Hitelcél: készlet, alapanyag és egyéb forgóeszköz finanszírozása. / Purpose: stock, materials and other working capital.',
                    'Hitelösszeg (minta): 1–250 millió Ft. / Amount (sample): HUF 1–250 million.',
                    'Futamidő (minta): 1–3 év. / Term (sample): 1–3 years.',
                    'Kamat (minta): évi 5%, fix. / Interest (sample): 5% a year, fixed.',
                    $binding,
                ]),
            ],
            [
                'code' => 'mock-szkp-likviditasi-hitel-max-plus',
                'title' => 'Széchenyi Likviditási Hitel MAX+',
                'loan_terms' => implode("\n", [
                    $warning,
                    'Hitelcél: a vállalkozás likviditásának megőrzése. / Purpose: keeping the business liquid.',
                    'Hitelösszeg (minta): 1–150 millió Ft. / Amount (sample): HUF 1–150 million.',
                    'Futamidő (minta): legfeljebb 3 év. / Term (sample): up to 3 years.',
                    'Kamat (minta): évi 5%, fix. / Interest (sample): 5% a year, fixed.',
                    $binding,
                ]),
            ],
        ];

        // updateOrCreate by code: Render runs DatabaseSeeder on every start, so reseeding must not duplicate rows.
        // Saving runs the model's CR-02 provenance validation, so an incomplete record fails loudly.
        foreach ($loans as $loan) {
            Opportunity::updateOrCreate(['code' => $loan['code']], $loan + $mock);
        }
    }
}
