import Head from 'next/head';
import ChatBox from '@/components/ChatBox';

export default function Home() {
  return (
    <>
      <Head>
        <title>kraislauf</title>
        <meta name="description" content="Learn how to recycle properly" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main className="min-h-screen p-4 md:p-8 bg-gray-50">
        <header className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-green-600">kraislauf</h1>
          <p className="text-gray-600 mb-4">Learn how to recycle properly</p>
        </header>
        
        <div className="max-w-3xl mx-auto">
          <ChatBox />
          
          <div className="mt-8 p-4 bg-white rounded-lg shadow text-center">
            <h2 className="text-xl font-semibold text-green-600 mb-2">How It Works</h2>
            <p className="text-gray-700">
              Ask our AI assistant about recycling specific items, or upload a photo
              of an item you're unsure about. Get instant guidance on proper recycling practices.
            </p>
          </div>
        </div>
      </main>
    </>
  );
}