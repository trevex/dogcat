import { useState } from 'react';
import type { NextPage } from 'next'
import dynamic from "next/dynamic";
import Head from 'next/head'

const Game = dynamic(() => import("../components/Game"), {
    ssr: false,
});

const Home: NextPage = () => {
    const [score, setScore] = useState(0);

    return (
        <div>
            <Head>
                <title>DogCat</title>
                <meta name="description" content="Basically two-ended snake" />
                <link rel="icon" href="/favicon.ico" />
            </Head>
            <div className="flex flex-col items-center">
                <div>
                    Score: {score}
                </div>
                <div className="border-solid border-4 border-slate-600 rounded-lg">
                    <Game size={800} cells={25} onScoreChange={setScore} />
                </div>
            </div>
        </div>
    )
}

export default Home
